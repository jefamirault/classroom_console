include OnApiHelper

class SyncJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = args[0] || {}

    force_new_on_api_token
    Course.full_sync

    if options[:repeat]
      SyncJob.set(wait: 10.minutes).perform_later options
    end
  end
end
