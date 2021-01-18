class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :section
  has_one :assignment, through: :section
  has_one :course, through: :section

  enum role: { student: 0, teacher: 1 }

  before_update :log_changes
  after_create :log_create

  include OnApiHelper

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

end