class SyncJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Course.refresh_sis_courses
    Section.refresh_sis_sections
  end
end
