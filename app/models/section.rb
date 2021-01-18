class Section < ApplicationRecord
  belongs_to :course
  has_many :enrollments
  has_many :users, through: :enrollments
  has_one :assignment


  scope :missing_canvas_id, -> { where(canvas_id: nil) }
  scope :has_canvas_id, -> { where.not(canvas_id: nil) }

  include CanvasApiHelper
  include OnApiHelper


  def to_s
    self.name
  end


  def sync
    # check sis for opt-in assignment
    sync_sis_assignments

    sync_canvas_enrollments
  end

  def self.sync_all_grades
    Section.where(sync_grades: true).each &:sync
  end

  def sync_sis_assignments
    if self.assignment
    #  already synced
    else
      assignments = on_api_get_json "assignment/forsection/#{sis_id}", on_api_token
      match_assignment = assignments.select{|a| a['AssignmentDescription'].downcase == 'canvas grade'}
      if match_assignment.size > 1
        puts "Multiple opt-in assignments found: skipping section #{self} sis_id: #{self.sis_id}"
        return nil
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

  def sync_canvas_enrollments
    if canvas_id.nil?
      return "Cannot sync Canvas enrollments without canvas_id."
    end
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
            enrollment.post_grade
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
end
