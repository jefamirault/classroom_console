
include OnApiHelper

class SchoolYear < ApplicationRecord
  has_many :terms

  validates :sis_id, uniqueness: true

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
    elsif start_date && start_date > Date.today
      'Not Started'
    elsif end_date && end_date < Date.today
      'Concluded'
    else
      ''
    end
  end

  def self.sync_sis_school_years
    json = on_api_get_school_years
    data = json[:data]
    if data
      school_years = data.map do |sy|
        {
          name: sy['SchoolYearLabel'],
          sis_id: sy['SchoolYearId'],
          start_date: sy['BeginSchoolYear'],
          end_date: sy['EndSchoolYear'],
        }
      end
      SchoolYear.upsert_all school_years, unique_by: [:sis_id, :name]
    end
  end
end
