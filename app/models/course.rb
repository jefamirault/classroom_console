class Course < ApplicationRecord
  has_many :sections

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

  def self.refresh_sis_courses(courses_json)
    puts "Refreshing OnCampus Courses..."

    course_ids = Course.pluck(:sis_id)
    course_hash = {}
    course_ids.each {|c| course_hash[c] = true}

    discovered = 0
    courses_json.each do |json|
      sis_id = json['OfferingId']
      if course_hash[sis_id]
      # if Course.exists? sis_id: sis_id
        # Do nothing
      else
        discovered += 1
        Course.create_from_json json
      end
    end
    ["Discovered #{discovered} New Courses", "Total Courses: #{Course.count}"]
  end
end
