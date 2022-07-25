class Course < ApplicationRecord
  has_many :sections
  has_many :enrollments, through: :sections

  validates_uniqueness_of :sis_id

  ACCOUNT_ID = ENV['ACCOUNT_ID']

  def to_s
    self.name
  end

  def self.create_from_json(json)
    course = Course.new
    course.sis_id = json['OfferingId']
    course.name = json['CourseTitle']
    course.is_active = json['IsActive']
    course.course_length = json['CourseLength']
    course.save
  end

  def self.refresh_sis_courses(courses_json = Course.request_sis_courses)
    puts "Refreshing OnCampus Courses..."

    course_ids = Course.pluck(:sis_id)
    course_hash = {}
    course_ids.each {|c| course_hash[c] = true}

    discovered = 0

    courses_json.each do |json|
      sis_id = json['OfferingId']
      if course_hash[sis_id]
      # course already exists locally, do nothing
      else
        next unless json['IsActive']
        discovered += 1
        Course.create_from_json json
      end
    end
    ["Discovered #{discovered} New Courses", "Total Courses: #{Course.count}"]
  end


  extend OnApiHelper

  def self.request_sis_courses
    response = on_api_get 'academics/course'
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error while requesting Course data via ON API."
    end
  end

  include CanvasApiHelper
  extend CanvasApiHelper

  def sync_sis_enrollments
    sections.each &:sync_sis_enrollments
  end

  def create_canvas_sections
    sections.each &:create_canvas_section
  end
  def enroll_users_in_canvas
    sections.each &:enroll_users_in_canvas
  end

  def post_to_canvas(term)
    raise 'Missing Canvas ID for term' if term.canvas_id.nil?
    course_params = {
      course: {
        name: self.name,
        course_code: self.name,
        term_id: term.canvas_id
      }
    }.to_json
    canvas_api_post "accounts/#{ACCOUNT_ID}/courses", course_params
  end
end
