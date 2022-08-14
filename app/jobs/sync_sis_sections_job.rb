class SyncSisSectionsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Section.refresh_sis_sections
  end
end