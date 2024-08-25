include OnApiHelper

class SyncSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = args[0] || {}

    puts
    if options[:sync_profile_id]
      # Sync a single profile
      # TODO: sanitize params
      # raise 'Invalid ID for Sync' if options[:sync_profile_id].class != Fixnum
      SyncProfile.find(options[:sync_profile_id]).subscriptions.where(enabled: true).each &:sync
    else
      # Sync everything
      Subscription.where(enabled: true).all.each do |s|
        s.sync
      end
    end

    puts

    if options[:repeat]
      SyncSubscriptionsJob.set(wait: 10.minutes).perform_later options
    end
  end
end
