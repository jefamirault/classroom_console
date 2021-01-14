class Course < ApplicationRecord
  has_many :sections

  def to_s
    self.name
  end
end
