FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User##{n}" }
    # sequence(:sis_id, 10000)
    sequence(:sis_id)
    # sequence(:canvas_id, 5000)
    sequence(:canvas_id)
    email { "#{name.downcase.gsub(%r{\W}, '')}@example.com" }
    factory :student
    factory :teacher
  end

  factory :course do
    sequence(:name) { |n| "Course##{n}" }
    # sequence(:sis_id, 1000)
    sequence(:sis_id)
  end

  factory :section do
    sequence(:name) { |n| "Section##{n}" }
    sequence(:sis_id)
    sequence(:canvas_id)
    course
  end
end

def course_with_sections(sections_count: 3)
  FactoryBot.create(:course) do |course|
    FactoryBot.create_list(:section, sections_count, course: course)
  end
end

def assign_sample_users(users, courses)
  teachers = users.first(2)
  students = users.drop(4)
  teachers_queue = teachers
  courses.each do |t|
    teacher = teachers_queue.pop
    t.sections.each do |s|
      Enrollment.create section: s, user: teacher, role: :teacher
    end
  end

  students.each do |student|
    courses.each do |c|
      section = c.sections.sort_by{|section| section.enrollments.count}.first
      Enrollment.create section: section, user: student, role: :student
    end
  end
end

def generate_sample
  users = 60.times.map do
    FactoryBot.create :user
  end
  courses = 2.times.map { course_with_sections }
  assign_sample_users users, courses
end