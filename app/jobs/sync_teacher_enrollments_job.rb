include OnApiHelper

class SyncTeacherEnrollmentsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = args[0] || {}

    @user = User.find options[:user_id]
    user_sis_id = @user.sis_id

    response = on_api_get_teacher_sections(user_sis_id)
    if response[:success]
      if response[:data].class != Array
        return
      #   No sections found. Do nothing
      end
      @teacher_sections = response[:data].map do |section|
        {
          section_sis_id: section['Id'],
          lead_section_id: section['LeadSectionId'],
          name: section['Name'],
          course_code: section['CourseCode'],
          duration_id: section['Duration']['DurationId']
        }
      end.reject {|s| s[:section_sis_id] != s[:lead_section_id]} # OnCampus would count a 2-semester course as 2 sections, ignore this and assume enrollments are the same for the whole course
    else
      puts 'ON API request failed.'
    end

    # Make sure the user is enrolled in each section in @teacher_sections
    if @teacher_sections
      @teacher_sections.each do |s|
        section = Section.find_by_sis_id (s[:section_sis_id])
        if section
          #   make sure the enrollment exists
          Enrollment.find_or_create_by(user: @user, section: section, role: 'teacher')
        else
          # Do nothing
        end
      end
    else
      puts "Could not find teacher sections for user: #{@user}"
    end
  end
end
