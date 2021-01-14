class Section < ApplicationRecord
  belongs_to :course
  has_many :enrollments
  has_many :users, through: :enrollments

  def to_s
    self.name
  end
end
