class RequestSisAssignmentsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Section.sync_all_sis_assignments
  end
end