class SyncSisCoursesJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Course.refresh_sis_courses
  end
end
