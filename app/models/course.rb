class Course < ApplicationRecord
  has_many :sections, dependent: :destroy
  has_many :enrollments, through: :sections
  has_many :logs, as: :loggable
  has_many :events, through: :logs

  validates_uniqueness_of :sis_id

  ACCOUNT_ID = ENV['ACCOUNT_ID']

  def to_s
    self.name
  end

  def self.create_from_json(json)
    course = Course.new
    course.sis_id = json['OfferingId']
    course.name = json['CourseTitle']
    course.is_active = json['IsActive']
    course.course_length = json['CourseLength']
    course.save
    course
  end

  def self.full_sync
    Course.refresh_sis_courses
    Section.refresh_sis_sections
    Term.sync_terms
    return 'Select which courses to sync with Canvas' if Course.where(sync_course: true).count == 0
    Section.sync_all_sis_assignments
    Course.sync_all_sis_enrollments
    Enrollment.get_sis_teacher_enrollments
    User.refresh_sis_emails
    User.sync_canvas_users
    Course.sync_canvas_courses
    Course.sync_canvas_enrollments
  end

  def self.refresh_sis_courses(courses_json = Course.request_sis_courses)
    result = { new_courses: [] }
    puts "Refreshing OnCampus Courses..."

    course_ids = Course.pluck(:sis_id)
    course_hash = {}
    course_ids.each {|c| course_hash[c] = true}


    courses_json.each do |json|
      sis_id = json['OfferingId']
      if course_hash[sis_id]
      # course already exists locally, do nothing
      else
        next unless json['IsActive']
        result[:new_courses] << Course.create_from_json(json)
      end
    end
    if result[:new_courses].any?
      event = Event.create label: 'Sync SIS Courses', description: "Detected #{result[:new_courses].count} new courses."
      result[:new_courses].each do |c|
        Log.create event_id: event.id, loggable_id: c.id, loggable_type: 'Course'
      end
    end
    result
  end

  def sync_with_canvas(options = {})
    result = { updated_sections: [],
               created_canvas_courses: [],
               created_canvas_sections: [],
               enrolled_canvas_users: [] }
    description = ""

    # detect existing Canvas sections
    self.sections.where(canvas_id: nil).each do |s|
      updated_section = s.detect_canvas_section[:updated_section]
      if updated_section
        result[:updated_sections] << updated_section
      end
    end

    # create missing Canvas sections
    sections_missing_from_canvas = self.sections.where(canvas_id: nil)
    create_course_for_these_terms = sections_missing_from_canvas.map(&:term).uniq


    create_course_for_these_terms.each do |term|
      c = create_canvas_course term
      if c[:created_canvas_course]
        result[:created_canvas_courses] << c[:created_canvas_course]
      end
    end

    # reload sections now that they have been updated with canvas_course_id
    sections_missing_from_canvas = self.sections.where(canvas_id: nil)

    result[:created_canvas_sections] = []

    sections_missing_from_canvas.each do |section|
      result[:created_canvas_sections] << section.create_canvas_section[:updated_section]
    end

    # Create logs
    unless options[:quiet]
      description << "Detected existing Canvas records for #{result[:updated_sections].size} sections. " if result[:updated_sections].any?
      description << "Created #{result[:created_canvas_sections].size} new Canvas sections. " if result[:created_canvas_sections].any?
      description << "Created #{result[:created_canvas_courses].size} new Canvas courses." if result[:created_canvas_courses].any?

      event = if result[:updated_sections].any? || result[:created_canvas_sections].any? || result[:created_canvas_courses].any?
                Event.make 'Sync Course with Canvas', description
              else
                nil
              end

      if result[:updated_sections].any?
        result[:updated_sections].each do |s|
          Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
        end
      end
      if result[:created_canvas_sections].any?
        result[:created_canvas_sections].each do |s|
          Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
        end
      end
      if result[:created_canvas_courses].any?
        result[:created_canvas_courses].each do |c|
          Log.create event_id: event.id, loggable_id: c.id, loggable_type: 'Course'
        end
      end
    end

    result
  end

  extend OnApiHelper
  include CanvasApiHelper
  extend CanvasApiHelper

  def sync_sis_enrollments(options = {})
    new_users = []
    new_enrollments = []
    self.sections.each do |section|
      result = section.sync_sis_enrollments
      new_users += result[:new_users]
      new_enrollments += result[:new_enrollments]
    end
    unless options[:quiet]
      if new_enrollments.any?
        description = "Detected #{new_enrollments.size} new enrollments."
        description << " Detected #{new_users.size} new users." if new_users.any?
        event = Event.create label: 'Sync SIS Enrollments', description: description
        new_enrollments.map(&:section).uniq.each do |s|
          Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
        end
        new_users.each do |u|
          Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
        end
      end
    end
    { new_users: new_users, new_enrollments: new_enrollments }
  end
  def self.sync_all_sis_enrollments
    puts "Checking for new SIS Enrollments..."
    new_users = []
    new_enrollments = []
    Course.all.each do |course|
      result = course.sync_sis_enrollments quiet: true
      new_users += result[:new_users]
      new_enrollments += result[:new_enrollments]
    end
    if new_enrollments.any?
      description = "Detected #{new_enrollments.size} new enrollments."
      description << " Detected #{new_users.size} new users." if new_users.any?
      event = Event.create label: 'Sync SIS Enrollments', description: description
      new_enrollments.map(&:section).uniq.each do |s|
        Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
      end
      new_users.each do |u|
        Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
      end
    end
    { new_users: new_users, new_enrollments: new_enrollments }
  end

  def create_canvas_course(term)
    result = { created_canvas_course: nil }
    sections = self.sections.where(term: term)
    raise 'Canvas Course ID already present for section' unless sections.map{|s| s.canvas_course_id.nil?}.reduce :&

    response = self.post_to_canvas(term)
    raise 'Something went wrong. Failed to create Canvas course.' unless response.code == '200'
    result[:created_canvas_course] = self
    json = JSON.parse response.body

    sections.each do |s|
      s.canvas_course_id = json['id']
      s.save
    end
    result
  end

  def sync_canvas_sections
    sections.each &:sync_canvas_section
  end
  def enroll_users_in_canvas(options = {})
    result = { detected_canvas_enrollments: [], created_canvas_enrollments: [] }

    self.sections.each do |s|
      increment = s.enroll_users_in_canvas options
      result[:detected_canvas_enrollments] += increment[:detected_canvas_enrollments]
      result[:created_canvas_enrollments] += increment[:created_canvas_enrollments]
    end

    # create logs
    unless options[:quiet]
      description = ""
      if result[:detected_canvas_enrollments].any?
        description << "Detected #{result[:detected_canvas_enrollments].size} existing Canvas enrollments. "
      end
      if result[:created_canvas_enrollments].any?
        description << "Created #{result[:created_canvas_enrollments].size} new Canvas enrollments. "
      end
      description.strip!
      if result[:detected_canvas_enrollments].any? || result[:created_canvas_enrollments].any?
        event = Event.make "Sync Canvas Enrollments", description
        affected_sections = {}
        result[:detected_canvas_enrollments].each do |e|
          Log.create event_id: event.id, loggable_id: e.user_id, loggable_type: 'User'
          affected_sections[e.section_id] = true
        end
        result[:created_canvas_enrollments].each do |e|
          Log.create event_id: event.id, loggable_id: e.user_id, loggable_type: 'User'
          affected_sections[e.section_id] = true
        end
        affected_sections.each_key do |id|
          Log.create event_id: event.id, loggable_id: id, loggable_type: 'Section'
        end
      end
    end

    result
  end

  def self.sync_canvas_courses
    puts "Syncing Canvas Courses..."
    result = { updated_sections: [], created_canvas_courses: [], created_canvas_sections: [] }
    description = ""

    Course.where(sync_course: true).each do |c|
      increment = c.sync_with_canvas quiet: true
      result[:updated_sections] += increment[:updated_sections]
      result[:created_canvas_courses] += increment[:created_canvas_courses]
      result[:created_canvas_sections] += increment[:created_canvas_sections]
    end

    description << "Detected existing Canvas records for #{result[:updated_sections].size} sections. " if result[:updated_sections].any?
    description << "Created #{result[:created_canvas_sections].size} new Canvas sections. " if result[:created_canvas_sections].any?
    description << "Created #{result[:created_canvas_courses].size} new Canvas courses." if result[:created_canvas_courses].any?

    # create logs
    event = if result[:updated_sections].any? || result[:created_canvas_sections].any? || result[:created_canvas_courses].any?
              Event.make 'Sync Canvas Courses', description
            else
              nil
            end

    if result[:updated_sections].any?
      result[:updated_sections].each do |s|
        Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
      end
    end
    if result[:created_canvas_sections].any?
      result[:created_canvas_sections].each do |s|
        Log.create event_id: event.id, loggable_id: s.id, loggable_type: 'Section'
      end
    end
    if result[:created_canvas_courses].any?
      result[:created_canvas_courses].each do |c|
        Log.create event_id: event.id, loggable_id: c.id, loggable_type: 'Course'
      end
    end
    result
  end

  def self.sync_canvas_enrollments(options = {})
    puts "Syncing Canvas Enrollments..."
    SyncCanvasEnrollmentsJob.perform_later
  end
  def post_to_canvas(term)
    raise 'Missing Canvas ID for term' if term.canvas_id.nil?
    course_params = {
      course: {
        name: self.name,
        course_code: self.name,
        term_id: term.canvas_id
      }
    }.to_json
    canvas_api_post_response "accounts/#{ACCOUNT_ID}/courses", course_params
  end

  private

  def self.request_sis_courses
    response = on_api_get 'academics/course'
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error while requesting Course data via ON API."
    end
  end
end
