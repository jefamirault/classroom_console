class OnApiController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }

  def index

  end

  def get_school_years
    response = on_api_get_school_years
    if response[:success]
      @school_years = response[:data]
    else
      redirect_to on_api_get_school_years_path, notice: 'ON API request failed.'
    end
  end

  def get_terms
    response = on_api_get_terms
    if response[:success]
      @terms = response[:data]
    else
      redirect_to on_api_get_terms_path, notice: 'ON API request failed.'
    end
  end

  def get_courses
    response = on_api_get_courses
    if response[:success]
      @courses = response[:data]
    else
      redirect_to on_api_get_courses_path, notice: 'ON API request failed.'
    end
  end

  def get_sections
    response = on_api_get_sections
    if response[:success]
      @sections = response[:data]
    else
      redirect_to on_api_get_sections_path, notice: 'ON API request failed.'
    end
  end

  def get_teacher_sections
    teacher_sis_id = params[:teacher_sis_id]&.to_i
    # user search
    if teacher_sis_id
      response = on_api_get_teacher_sections(teacher_sis_id)
      if response[:success]
        @teacher_sections = response[:data]
      else
        redirect_to on_api_get_teacher_sections_path, notice: 'ON API request failed.'
      end
    end
  end

  def get_assignments
    section_sis_id = params[:section_sis_id]&.to_i
    # user search
    if section_sis_id
      response = on_api_get_assignments(section_sis_id)
      if response[:success]
        @assignments = response[:data]
      else
        redirect_to on_api_get_assignments_path, notice: 'ON API request failed.'
      end
    end
  end

  def get_assignment_grades
    section_sis_id = params[:section_sis_id]&.to_i
    assignment_sis_id = params[:assignment_sis_id]&.to_i
    # user search
    if section_sis_id && assignment_sis_id
      response = on_api_get_assignment_grades(assignment_sis_id, section_sis_id)
      if response[:success]
        @assignment_grades = response[:data]
      else
        redirect_to on_api_get_assignment_grades_path, notice: 'ON API request failed.'
      end
    end
  end

  def get_departments
    response = on_api_get_departments
    if response[:success]
      @departments = response[:data]
    else
      redirect_to on_api_get_departments_path, notice: 'ON API request failed.'
    end
  end

  def get_roles
    response = on_api_get_roles
    if response[:success]
      @roles = response[:data]
    else
      redirect_to on_api_get_roles_path, notice: 'ON API request failed.'
    end
  end

  def get_users
    # user search
    response = on_api_get_users(start_row: params[:start_row], end_row: params[:end_row])
    if response[:success]
      @users = response[:data]
    else
      redirect_to on_api_get_users_path, notice: 'ON API request failed.'
    end
  end
end