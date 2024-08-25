module ApplicationHelper
  def nav_selected(path)
    if params[:controller] == path
      'active'
    else
      ''
    end
  end

  def canvas_section_path(section)

  end

  def loggable_path(log)
    loggable = log.loggable
    case log.loggable_type
    when 'Course'
      course_path loggable
    when 'Section'
      section_path loggable
    when 'User'
      user_path loggable
    when 'Term'
      term_path loggable
    else
      raise 'Failed to generate path. Unexpected Loggable Type'
    end

  end
end

def boolstr(val)
  (!!val).to_s.titleize
end