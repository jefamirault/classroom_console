class Section < ApplicationRecord
  belongs_to :course, counter_cache: true
  belongs_to :term
  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_one :assignment, dependent: :destroy
  has_many :logs, as: :loggable
  has_many :events, through: :logs

  scope :missing_canvas_id, -> { where(canvas_id: nil) }
  scope :has_canvas_id, -> { where.not(canvas_id: nil) }

  include CanvasApiHelper
  include OnApiHelper

  SIS_SCHOOL_YEAR = ENV['SIS_SCHOOL_YEAR']
  SIS_LEVEL_NUM = ENV['SIS_LEVEL_NUM']

  validates_uniqueness_of :sis_id

  def to_s
    self.name
  end


  def sync
    sync_sis_enrollments

    sync_sis_assignments

    sync_canvas_section

    sync_canvas_enrollments
  end



  def self.sync_all_grades
    Section.where(sync_grades: true).each &:sync
  end

  def sync_sis_assignments(options = {})
    result = { new_opt_in: nil }
    if self.assignment
    #  already synced
    else
      # assignments = on_api_get_json "assignment/forsection/#{sis_id}"
      assignments = on_api_get_json "academics/assignment", "&leadSectionId=#{sis_id}"
      ################################################################################################
      ## Determines how to configure a course in OnCampus so that it opts in to be synced with Canvas
      ################################################################################################
      match_assignment = assignments.select{|a| a['AssignmentType'] && a['AssignmentType'].downcase == 'canvas grade'}
      if match_assignment.size > 1
        puts "WARNING: Multiple opt-in assignments found: skipping section #{self} sis_id: #{self.sis_id}"
        return result
      end
      opt_in_assignment = match_assignment.first
      if opt_in_assignment.nil?
        #  don't sync grades
      else
        sis_id = opt_in_assignment['AssignmentId']
        # check if assignment exists locally
        if self.assignment.nil?
          # add if missing
          puts "Adding Opt-In Assignment locally for section: #{self}"
          a = Assignment.new sis_id: sis_id
          self.assignment = a
          if self.sync_grades.nil?
            self.sync_grades = true
            self.course.update sync_course: true
          end
          if self.save
            result[:new_opt_in] = self
          end
        else
          # assignment previously added, do nothing
        end
      end
    end

    unless options[:quiet] || result[:new_opt_in].nil?
      event = Event.make 'Check for new Opt-In', "Detected new opt-in assignment for section #{self}."
      Log.create event_id: event.id, loggable_id: self.id, loggable_type: 'Section'
    end

    result
  end

  def self.sync_all_sis_assignments
    puts "Checking OnCampus for Opt-In Assignments..."
    RequestSisAssignmentsJob.perform_now
  end

  def enroll_users_in_canvas(options = {})
    result = { detected_canvas_enrollments: [], created_canvas_enrollments: [] }
    # detect existing Canvas enrollments
    result1 = sync_canvas_enrollments options
    result[:detected_canvas_enrollments] += result1[:detected_canvas_enrollments]

    # add missing Canvas enrollments
    enrollments.where(enrolled_in_canvas: nil).each do |e|
      result[:created_canvas_enrollments] += e.post_to_canvas[:created_canvas_enrollments]
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

  # get grades from Canvas
  def sync_canvas_enrollments(options = {})
    raise 'Cannot sync Canvas enrollments without canvas_id.' if canvas_id.nil?

    result = { detected_canvas_users: [], detected_canvas_enrollments: [] }

    errors = nil
    canvas_api_get_paginated("sections/#{self.canvas_id}/enrollments").each do |e|
      json = {
          canvas_user_id: e['user_id'],
          sis_section_id: e['sis_section_id'],
          canvas_section_id: e['course_section_id'],
          canvas_course_id: e['course_id'],
          sis_user_id: e['sis_user_id'],
          name: e['user'] ? e['user']['name'] : nil,
          current_grade: e['grades'] ? e['grades']['current_score'] : nil
      }
      user = User.find_by_sis_id json[:sis_user_id].to_i
      next if user.nil?
      # update canvas_id and enrolled_in_canvas
      if user.canvas_id.nil?
        if user.update canvas_id: json[:canvas_user_id]
          result[:detected_canvas_users] << user
        end
      end
      enrollment = Enrollment.where(user_id: user.id, section_id: self.id).first
      next if enrollment.nil?
      unless enrollment.enrolled_in_canvas
        if enrollment.update enrolled_in_canvas: true
          result[:detected_canvas_enrollments] << enrollment
        end
      end

      if self.users.include? user
        enrollment = self.enrollments.find {|e| e.user == user}
        if enrollment.grade != json[:current_grade]
          enrollment.grade = json[:current_grade]
          if enrollment.save
            # TODO SKIP WHILE TESTING
            # enrollment.post_grade
            puts "ATTENTION: Skipping grade post: #{enrollment}"
          end
        end
      else
        puts "WARNING: Canvas section #{self} contains unexpected enrollment: #{json}"
      end
    end
    if errors.nil?
      self.last_sync = Time.now
      save
    end
    result
  end

  def self.refresh_sis_rosters(rosters_json)
    # Set up Hashmaps for efficient access
    course_hash = {}
    Course.all.each {|c| course_hash[c.sis_id] = c}

    section_hash = {}
    Section.all.each {|s| section_hash[s.sis_id] = s}

    user_hash = {}
    User.all.each {|u| user_hash[u.sis_id] = u}

    rosters_json.each do |json|
      section = section_hash[json['sis_section_id']]
      course = course_hash[json['sis_course_id']]

      if course.nil?
        next
        # raise "Course not found for section:\n#{json}"
        # TODO deal with ignore list
      end

      # Parse JSON for relevant section attributes
      section_attributes = {
          name: json['name'],
          sis_id: json['sis_section_id'],
          course_id: course.id,
          # starting_semester: json['starting_semester']
          # TODO implement Terms
      }

      # Create section if missing
      if section.nil?
        section = Section.create section_attributes
      else
        # Update section if any changes
        # TODO
      end

      # Create Enrollments if missing
      new_enrollments = []
      json['roster'].each do |user_json|
        user = user_hash[user_json['sis_id']]
        unless section.users.include? user
          new_enrollments << "Adding #{user} to #{section}"
          section.users << user
        end
      end
      if new_enrollments.any?
        puts "#{new_enrollments.count} User#{new_enrollments.count == 1 ? '' : 's'} enrolled in #{section}: "
      end
    end
  end

  def self.match_canvas_ids(canvas_sections_json)
    # set up efficient access of sections by sis_id
    section_hash = Hash.new
    Section.all.each do |section|
      section_hash[section.sis_id] = section
    end

    canvas_sections_json.each do |json|
      next if json['sis_section_id'].nil?
      next if json['sis_section_id'] =~ /_/ # invalid sis_id contains "_" character. Possibly result of a csv import?
      sis_id = json['sis_section_id'].to_i
      canvas_id = json['id'].to_i
      section = section_hash[sis_id]
      if section
        section.assign_attributes canvas_id: canvas_id
        if section.changed?
          puts "Section updated: #{section}, #{section.changes}"
          section.save
        end
      end
    end
  end

  def self.create_from_json(json)
    id = json['Id']

    # Skip wihout valid Section SIS ID
    return nil if id.nil? || id < 1

    if id.class != Fixnum
      raise "Error parsing Section json, ID must be a number"
    end

    section = Section.new
    section.sis_id = id
    section.name = json['Name']
    section.course = Course.find_by_sis_id json['OfferingId']

    # ignore sections from inactive courses
    return nil if section.course.nil?

    course_length = section.course.course_length
    term_name = if course_length == 1
      json['Duration']['SchoolYearLabel'] + ' ' + json['Duration']['Name']
    elsif course_length == 2
      json['Duration']['SchoolYearLabel'] + " Full Year"
    end

    result = {}

    term = Term.find_by_name term_name
    if term.nil?
      term = Term.create name: term_name, sis_id: json['Duration']['Id']
      result[:new_term] = term
    end
    section.term_id = term.id
    if section.save
      result[:new_section] = section
      result
    else
      raise "Something went wrong. Failed to update section #{section}"
    end
  end

  def self.refresh_sis_sections(sections_json = Section.request_sis_sections)
    puts "Refreshing OnCampus Sections..."
    new_sections = []
    new_terms = []
    sections_json.each do |json|
      # OnCampus has 2 sections for each full year course, 1st and 2nd semester. Exclude second semester section
      next if json['Id'] != json['LeadSectionId']
      section = Section.find_by_sis_id json['Id']
      if section.nil?
        result = Section.create_from_json json
        if result
          new_terms << result[:new_term] if result[:new_term]
          new_sections << result[:new_section] if result[:new_section]
        end
      end
    end
    if new_sections.any?
      description = "Detected #{new_sections.count} new sections."
      description << " Detected #{new_terms.count} new terms." if new_terms.any?
      event = Event.create label: 'Sync SIS Sections', description: description
      new_sections.each do |c|
        Log.create event_id: event.id, loggable_id: c.id, loggable_type: 'Section'
      end
      if new_terms.any?
        new_terms.each do |t|
          Log.create event_id: event.id, loggable_id: t.id, loggable_type: 'Term'
        end
      end
    end
  end

  extend OnApiHelper

  def sync_sis_enrollments
    if self.sis_id.nil? || self.sis_id < 1
      raise 'Cannot sync Section without valid SIS_ID'
    end
    sis_roster = on_api_get_json 'academics/enrollment', "&sectionID=#{self.sis_id}"

    new_users = []
    new_enrollments = []

    old_enrollments_by_sis_id = {}
    self.users.each do |user|
      old_enrollments_by_sis_id[user.sis_id] = true
    end

    sis_roster.each do |student|
      # match by sis_id if user exists, otherwise create user with sis_id + name

      sis_user_id = student['UserId']

      if old_enrollments_by_sis_id[sis_user_id]
      #  enrollment already synced
      else
      #  Newly detected enrollment, create user if they do not exist, add user to section
        user = User.create_with(name: student['Name'], email: nil).find_or_create_by(sis_id: sis_user_id)
        if user.new_record?
          if user.sis_id.class != Fixnum || user.sis_id < 1
            raise 'Cannot create user without valid SIS_ID'
          end
          if user.name.class != String
            raise 'Cannot create user. Name must be a String'
          end
          # allow user to be created without a password
          if user.save validate: false
            new_users << user
          end
        end

        new_enrollments << Enrollment.create(user_id: user.id, section_id: self.id, role: :student)
      end
    end
    { new_users: new_users, new_enrollments: new_enrollments }
  end

  def self.request_sis_sections(options = {})
    puts "Getting SIS Sections for School Year #{SIS_SCHOOL_YEAR.gsub("%20", " ")}..."
    parameters = "&schoolYear=#{SIS_SCHOOL_YEAR}&levelNum=#{SIS_LEVEL_NUM}"
    response = on_api_get 'academics/section', parameters, options
    if response.code == '200'
      JSON.parse(response.body).uniq!
    else
      raise "Error while requesting Section data via ON API. Parameters: \"#{parameters}\" #{response.body}"
    end
  end

  extend CanvasApiHelper

  def all_sections_for_course
    course.sections.select{|s| s.term == self.term}
  end

  # create canvas section if possible, record canvas ids if already present
  def create_canvas_section
    result = { updated_section: nil }

    if self.canvas_course_id.nil?
      raise 'Error: Cannot create Canvas section before course'
    end

    unless canvas_id.nil?
      puts 'Skipping create Canvas Section, canvas_id is already present.'
      return nil
    end

    # canvas_id not present, check if course/section already exist in canvas
    # link existing canvas section and return update record or create it now
    # section = sync_canvas_section
    # return section unless section.nil?

    body = {
      course_section: {
        name: self.name,
        sis_section_id: self.sis_id
      }
    }.to_json


    response = canvas_api_post "courses/#{self.canvas_course_id}/sections", body
    raise "Something went wrong. #{response['errors']}" if response['errors']
    self.canvas_id = response['id']
    if save
      result[:updated_section] = self
    else
      raise "Something went wrong. Failed to update section #{self}"
    end
    result
  end

  # if canvas section exists with matching sis_id, find it and record canvas section_id and + canvas course_id, return updated section
  # return nil if canvas section does not exist
  def detect_canvas_section
    result = { updated_section: nil }
    # find canvas section by sis_id
    response = canvas_api_get "sections/sis_section_id:#{self.sis_id}"
    if response.code == '200'
      # Section already exists in Canvas, record canvas section_id and course_id
      section_json = JSON.parse response.body
      canvas_id = section_json['id']
      canvas_course_id = section_json['course_id']
      if self.update canvas_id: canvas_id, canvas_course_id: canvas_course_id
        result[:updated_section] = self
      end
      result
    elsif response.code == '404'
      # Section does not exist in Canvas, create it
      puts "Section (sis_id = #{self.sis_id}) not found in canvas."
      result
    elsif response.code == '401'
      raise "ERROR: Could not authenticate to Canvas API. Is access token expired?"
    else
      raise "Something unexpected happened."
    end
  end

  def sync_canvas_section
    if canvas_id.nil?
      section = detect_canvas_section[:updated_section] || self.create_canvas_section
    end
  end

  def remove_sis_id_from_canvas
    body = {
      course_section: {
        sis_section_id: ''
      }
    }.to_json
    canvas_api_put "sections/#{self.canvas_id}", body
  end

  def delete_course_from_canvas
    body = {
      event: 'delete'
    }.to_json
    canvas_api_delete "courses/#{self.canvas_course_id}", body
  end
end
