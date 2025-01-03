class SchoolYear < ApplicationRecord
  has_many :terms

  def to_s
    self.name
  end

  def current?
    if !start_date.nil? && !self.end_date.nil?
      start_date <= Date.today && Date.today <= end_date
    else
      nil
    end
  end

  def status
    if self.current?
      'Active'
    elsif start_date > Date.today
      'Not Started'
    else
      'Concluded'
    end
  end
end
