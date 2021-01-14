module CoursesHelper
  def course_link(course)
    link_to course.name, course_path(course)
  end
end
