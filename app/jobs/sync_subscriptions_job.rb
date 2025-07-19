include OnApiHelper

class SyncSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = args[0] || {}

    puts
    if options[:sync_profile_id]
      puts "Syncing a single profile: #{options[:sync_profile_id]}"
      # TODO: sanitize params
      # raise 'Invalid ID for Sync' if options[:sync_profile_id].class != Fixnum
      SyncProfile.find(options[:sync_profile_id]).subscriptions.where(enabled: true).each &:sync
    else
      puts 'Syncing everything...'
      Subscription.where(enabled: true).all.each do |s|
        s.sync
      end
    end

    puts

    if options[:repeat]
      interval = options[:interval] || 10.minutes
      SyncSubscriptionsJob.set(wait: interval).perform_later options
    end
  end
end
