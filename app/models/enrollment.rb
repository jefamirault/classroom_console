class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :section
  has_one :course, through: :section

  enum role: { student: 0, teacher: 1 }

end