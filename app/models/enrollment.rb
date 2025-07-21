class Enrollment < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :section, counter_cache: true
  has_one :assignment, through: :section
  has_one :course, through: :section

  enum role: { student: 0, teacher: 1 }

  validates :user, :section, presence: true

  before_update :log_changes
  after_create :log_create

  include OnApiHelper
  include CanvasApiHelper

  def log_create
    change = GradeChange.create enrollment: self, old_value: nil, new_value: self.grade, time: Time.now.utc.to_fs(:db)
    self.last_grade_change_id = change.id
  end

  def log_changes
    previous_change = last_grade_change
    change = changes['grade']
    if change
      change = GradeChange.create enrollment: self, old_value: change[0], new_value: change[1], time: Time.now.utc.to_fs(:db)
      self.last_grade_change_id = change.id
      change.update previous_change_id: previous_change ? previous_change.id : nil
      if previous_change
        previous_change.update next_change_id: change.id
      end
    end
  end

  def last_grade_change
    self.last_grade_change_id ? GradeChange.find(self.last_grade_change_id) : nil
  end
  alias_method :previous_change, :last_grade_change

  def grade_updated_at
    last_grade_change ? last_grade_change.time : nil
  end

  def grade_at_time(time)
    change = last_grade_change
    while change.time > time
      change = change.previous_change
    end
    change.new_value
  end

  # list of current and all previous grade changes for the given enrollment with times
  def grade_history
    grades = []
    current_change = self.last_grade_change
    until current_change.nil?
      grades << [current_change.new_value, current_change.time]
      current_change = current_change.prev
    end
  end

  def post_grade(options = {})
    if AdminSetting.first_or_create.allow_on_api_write
    #   Proceed if action is permitted
    else
      return "Cannot post grade. Writing to ON API disabled."
    end
    if section.assignment.nil?
      puts "Cannot post grade (#{grade} - #{user.name} without OnCampus assignment for section: #{section}"
      return nil
    end

    grade_object = {
        'GradebookGrade' => grade,
        'StudentUserId' => user.sis_id,
        'AssignmentId' => section.assignment.sis_id,
        'SectionId' => section.sis_id
    }
    if options[:debug]
      puts grade_object
    end
    on_api_post 'academics/assignmentgrade', on_api_token, grade_object
  end

  def post_to_canvas(options = {})
    raise 'Enrollment is missing a user' if user.nil?

    result = { created_canvas_enrollments: [] }

    # User must be created in Canvas before they can be enrolled in a Canvas course
    return result if user.canvas_id.nil?

    enrollment_type = self.role.capitalize + 'Enrollment'

    body = {
      enrollment: {
        user_id: user.canvas_id,
        type: enrollment_type,
        enrollment_state: 'active'
      }
    }.to_json

    response = canvas_api_post_response "sections/#{section.canvas_id}/enrollments", body, options
    if response.code == '200'
      self.enrolled_in_canvas = true
      if save
        result[:created_canvas_enrollments] << self
      end
      unless options[:quiet]
        puts "Enrollment Added: User: #{user}, Section: #{section}"
      end
    end
    result
  end

  def self.remove_duplicate_enrollments
    enrollments = Enrollment.all.order :user_id, :section_id
    last_user_id = nil
    last_section_id = nil
    enrollments.each do |e|
      repeat_user = (e.user_id == last_user_id)
      repeat_section = (e.section_id == last_section_id)
      if repeat_user && repeat_section
        e.destroy
      end
      last_user_id = e.user_id
      last_section_id = e.section_id
    end
  end
end