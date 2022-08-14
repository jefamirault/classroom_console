class SyncJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = args[0] || {}

    Course.full_sync

    if options[:repeat]
      SyncJob.set(wait: 1.minute).perform_later options
    end
  end
end
