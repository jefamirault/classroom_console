require 'net/http'
require 'uri'
require_relative 'export_helper'
require 'logger'

module OnApiHelper
  def on_api_url
    AdminSetting.first.on_api_path
  end
  def on_api_key
    AdminSetting.first.on_api_key
  end
  def on_api_secret
    AdminSetting.first.on_api_secret
  end
  def sis_school_year
    AdminSetting.first.sis_school_year
  end
  def sis_level_num
    AdminSetting.first.sis_level_num
  end

  include ExportHelper

  def on_authenticate
    raw_uri = "#{on_api_url}/authentication/login"
    puts "Authenticating to ON API: #{raw_uri}"
    uri = URI.parse(raw_uri)
    request = Net::HTTP::Post.new(uri)

    request["Content-Type"] = 'application/json'

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    request.body = {
        username: on_api_key,
        password: on_api_secret
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    # Responds with access token. Expires after 20 minutes without being used.
    response
  end


  def on_api_token(options = {})
    last_token = read_object 'timed_token'
    if last_token && last_token[:expire] > Time.now
      puts "Reusing existing ON API token. Expires at #{last_token[:expire]}" if options[:verbose]
      last_token[:token]
    else
      # token expired, reauthenticate for new token
      time = Time.now
      response = on_authenticate
      token = JSON.parse(response.body)['Token']
      timed_token = {
          token: token,
          expire: time + 20*60 # 20 minutes
      }
      puts "Created new ON API token. Expires at #{timed_token[:expire]}" if options[:verbose]
      write_object timed_token, 'timed_token'
      token
    end
  end

  def force_new_on_api_token(options = {})
    time = Time.now
    response = on_authenticate
    token = JSON.parse(response.body)['Token']
    timed_token = {
      token: token,
      expire: time + 20*60 # 20 minutes
    }
    puts "Created new ON API token. Expires at #{timed_token[:expire]}" if options[:verbose]
    write_object timed_token, 'timed_token'
    token
  end

  def on_api_post(route, token, body)
    # puts "POST #{on_api_url}/#{route}..."
    uri = URI.parse("#{on_api_url}/#{route}?t=#{token}")

    header = { 'Content-Type': 'application/json' }

  # Create the HTTP objects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)

    request.body = body.to_json

  # Send the request
    response = http.request(request)

    response
  end

  def on_api_get(route, parameters = nil, options = {})
    uri = URI.parse("#{on_api_url}/#{route}?t=#{on_api_token}#{parameters}")
    puts "GET #{on_api_url}/#{route}?t=*#{parameters}..." if options[:verbose]

    header = { 'Content-Type': 'application/json' }

  # Create the HTTP objects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri, header)

  # Send the request
    response = http.request(request)

    response
  end

  def on_api_get_json(route, parameters = nil)
    JSON.parse on_api_get(route, parameters).body
  end


  def on_api_get_school_years(options = {})
    response = on_api_get 'schoolinfo/allschoolyears'
    school_years = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: school_years
    }
  end

  def on_api_get_terms(school_year = sis_school_year)
    response = on_api_get 'schoolinfo/term', "&schoolYear=#{school_year}"
    terms = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: terms
    }
  end

  def on_api_get_courses
    response = on_api_get 'academics/course'
    courses = JSON.parse response.body
    {
      success: response.code == '200',
      response: response.body,
      data: courses
    }
  end

  def on_api_get_sections
    parameters = "&schoolYear=#{sis_school_year}&levelNum=#{sis_level_num}"
    response = on_api_get 'academics/section', parameters
    sections = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: sections
    }
  end

  def on_api_get_teacher_sections(user_sis_id)
    response = on_api_get '/academics/TeacherSection', "&schoolYear=#{sis_school_year}&userID=#{user_sis_id}"
    teacher_sections = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: teacher_sections
    }
  end

  def on_api_get_assignments(section_sis_id)
    response = on_api_get '/academics/assignment', "&leadSectionId=#{section_sis_id}"
    assignments = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: assignments
    }
  end
  def on_api_get_assignment_grades(assignment_sis_id, section_sis_id)
    response = on_api_get '/academics/AssignmentGrade', "&assignmentId=#{assignment_sis_id}&sectionId=#{section_sis_id}"
    assignment_grades = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: assignment_grades
    }
  end

  def on_api_post_grade(grade, user_sis_id, assignment_sis_id, section_sis_id)
    grade_object = {
      'GradebookGrade' => grade,
      'StudentUserId' => user_sis_id,
      'AssignmentId' => assignment_sis_id,
      'SectionId' => section_sis_id
    }
    on_api_post 'academics/assignmentgrade', on_api_token, grade_object
  end

  def on_api_get_departments(options = {})
    response = on_api_get '/academics/department'
    departments = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: departments
    }
  end

  def on_api_get_roles(options = {})
    response = on_api_get '/role/ListAll'
    roles = JSON.parse(response.body)
    {
      success: response.code == '200',
      response: response,
      data: roles
    }
  end
  def on_api_get_users(options = {})
    role_ids = options[:role_ids] || '29906,29907'
    start_row = options[:start_row] || 1
    end_row = options[:end_row] || 200
    response = on_api_get '/user/all', "&roleIDs=#{role_ids}&startrow=#{start_row}&endrow=#{end_row}"
    users = JSON.parse response.body
    {
      success: response.code == '200',
      response: response,
      data: users
    }
  end

end