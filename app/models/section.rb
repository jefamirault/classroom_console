class Section < ApplicationRecord
  belongs_to :course, counter_cache: true
  belongs_to :term
  has_many :enrollments
  has_many :users, through: :enrollments
  has_one :assignment


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

    sync_canvas_section if canvas_id.nil?

    sync_canvas_enrollments
  end



  def self.sync_all_grades
    Section.where(sync_grades: true).each &:sync
  end

  def sync_sis_assignments
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
        puts "Multiple opt-in assignments found: skipping section #{self} sis_id: #{self.sis_id}"
        return assignments
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
          end
          self.save
        else
          # assignment previously added, do nothing
        end
      end
    end
  end

  def self.sync_all_sis_assignments
    Section.all.each &:sync_sis_assignments
  end

  def enroll_users_in_canvas
    enrollments.each &:post_to_canvas
  end

  # get grades from Canvas
  def sync_canvas_enrollments
    raise 'Cannot sync Canvas enrollments without canvas_id.' if canvas_id.nil?

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
      end
    end
    if errors.nil?
      self.last_sync = Time.now
      save
    end
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

    term = Term.find_by_name term_name
    if term.nil?
      term = Term.create name: term_name, sis_id: json['Duration']['Id']
    end
    section.term_id = term.id
    section.save
  end

  def self.refresh_sis_sections(sections_json = Section.request_sis_sections)
    puts "Refreshing OnCampus Sections..."
    sections_json.each do |json|
      # OnCampus has 2 sections for each full year course, 1st and 2nd semester. Exclude second semester section
      next if json['Id'] != json['LeadSectionId']
      Section.create_from_json json
    end
  end

  extend OnApiHelper

  # def sync_term
  #   response = on_api_get 'academics/section', "&schoolYear=#{SIS_SCHOOL_YEAR}&levelNum=#{SIS_LEVEL_NUM}&OfferingID=#{course.sis_id}"
  #   if response.code == '200'
  #     JSON.parse(response.body).uniq
  #   else
  #     raise "Error while requesting Section data via ON API."
  #   end
  # end

  def sync_sis_enrollments
    if self.sis_id.nil? || self.sis_id < 1
      raise 'Cannot sync Section without valid SIS_ID'
    end
    sis_roster = on_api_get_json 'academics/enrollment', "&sectionID=#{self.sis_id}"
    sis_roster.each do |student|
      # match by sis_id if user exists, otherwise create user with sis_id + name
      user = User.create_with(name: student['Name'], email: nil).find_or_create_by(sis_id: student['UserId'])
      if user.new_record?
        if user.sis_id.class != Fixnum || user.sis_id < 1
          raise 'Cannot create user without valid SIS_ID'
        end
        if user.name.class != String
          raise 'Cannot create user. Name must be a String'
        end
        # allow user to be created without a password
        user.save validate: false
      end
      # Enroll user if not enrolled
      if enrollments.find_by_user_id user.id
      #  good
      else
        Enrollment.create user_id: user.id, section_id: self.id, role: :student
      end
    end
  end

  def self.request_sis_sections
    puts "Getting SIS Sections for School Year #{SIS_SCHOOL_YEAR}..."
    response = on_api_get 'academics/section', "&schoolYear=#{SIS_SCHOOL_YEAR}&levelNum=#{SIS_LEVEL_NUM}"
    if response.code == '200'
      JSON.parse(response.body).uniq!
    else
      raise "Error while requesting Section data via ON API."
    end
  end

  extend CanvasApiHelper

  def all_sections_for_course
    course.sections.select{|s| s.term == self.term}
  end

  def create_canvas_section
    unless canvas_id.nil?
      puts 'Skipping create Canvas Section, canvas_id is already present.'
      return nil
    end
    body = {
      course_section: {
        name: self.name,
        sis_section_id: self.sis_id
      }
    }.to_json

    if self.canvas_course_id.nil?
      create_canvas_course
    end

    if canvas_id.nil?
      response = canvas_api_post "courses/#{self.canvas_course_id}/sections", body
      raise "Something went wrong. #{response['errors']}" if response['errors']
      self.canvas_id = response['id']
      save
    else
      puts "Canvas section id present, skipping create canvas section."
    end

    enroll_users_in_canvas
  end

  def create_canvas_course
    sections = all_sections_for_course
    raise 'Canvas Course ID already present for section' unless sections.map{|s| s.canvas_course_id.nil?}.reduce :&

    response = course.post_to_canvas(self.term)
    sections.each do |s|
      s.canvas_course_id = response['id']
      s.save
    end
    sections.each &:create_canvas_section
  end

  # if canvas section exists with matching sis_id, find it and record canvas_id
  def sync_canvas_section
    # find canvas section by sis_id
    response = canvas_api_get "sections/sis_section_id:#{self.sis_id}"
    if response.code == '200'
      # Section already exists in Canvas, record section canvas_id
      section_json = JSON.parse response.body
      canvas_id = section_json['id']
      canvas_course_id = section_json['course_id']
      self.update canvas_id: canvas_id, canvas_course_id: canvas_course_id
    elsif response.code == '404'
      # Section does not exist in Canvas, create it
      puts "Section (sis_id = #{self.sis_id}) not found in canvas."
    elsif response.code == '401'
      puts "ERROR: Could not authenticate to Canvas API. Is access token expired?"
    else
      raise "Something unexpected happened."
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
