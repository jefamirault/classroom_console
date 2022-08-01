class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :section, counter_cache: true
  has_one :assignment, through: :section
  has_one :course, through: :section

  enum role: { student: 0, teacher: 1 }

  before_update :log_changes
  after_create :log_create

  include OnApiHelper
  include CanvasApiHelper

  def log_create
    change = GradeChange.create enrollment: self, old_value: nil, new_value: self.grade, time: Time.now.utc.to_s(:db)
    self.last_grade_change_id = change.id
  end

  def log_changes
    previous_change = last_grade_change
    change = changes['grade']
    if change
      change = GradeChange.create enrollment: self, old_value: change[0], new_value: change[1], time: Time.now.utc.to_s(:db)
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

  def post_grade(options = {})

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
    raise 'Enrollment failed. Does user exist in Canvas?' if user.canvas_id.nil?
    raise 'Enrollment failed. Does section exist in Canvas?' if section.canvas_id.nil?

    enrollment_type = self.role.capitalize + 'Enrollment'

    body = {
      enrollment: {
        user_id: user.canvas_id,
        type: enrollment_type,
        enrollment_status: 'active'
      }
    }.to_json

    response = canvas_api_post_response "sections/#{section.canvas_id}/enrollments", body, options
    if response.code == '200'
      self.enrolled_in_canvas = true
      save
      unless options[:quiet]
        puts "Enrollment Added: User: #{user}, Section: #{section}"
      end
    end
    response
  end

  extend OnApiHelper

  def self.get_sis_teacher_enrollments
    response = on_api_get "list/#{ENV['TEACHER_ENROLLMENTS_ID']}"
    raise "ON API Error" unless response.code == "200"
    enrollments = JSON.parse response.body

    enrollments.filter! {|e| e['FacultyUserID'] != 0}

    enrollments.each do |enrollment|
      sis_user_id = enrollment['FacultyUserID']
      next if sis_user_id == 0
      section_sis_id = enrollment['GroupID']
      teacher_name = "#{enrollment['FacultyFirstName']} #{enrollment['FacultyLastName']}"
      teacher_email = enrollment['EMail']

      section = Section.find_by_sis_id section_sis_id
      if section
        user = User.find_by_sis_id sis_user_id
        if user.nil?
          user_params = {
            sis_id: sis_user_id,
            name: teacher_name,
            email: teacher_email
          }
          user = User.create user_params
          if user
            puts "User created: #{user}"#  create user
          end
        end
        e = Enrollment.new
        e.section = section
        e.user = user
        e.role = 'teacher'
        e.save
        # add enrollment if it does not exist
      end
    end
  end

end