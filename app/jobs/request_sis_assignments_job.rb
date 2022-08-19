include OnApiHelper

class RequestSisAssignmentsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = if args.any?
                args.first
              else
                {}
              end

    if options[:id]
      Section.find(options[:id]).sync_sis_assignments
    elsif options[:ids]
      force_new_on_api_token
      options[:ids].each_slice((options[:ids].size / 10.0).ceil) do |ids|
        RequestSisAssignmentsJob.perform_later batch: ids
      end
    elsif options[:batch]
      Section.find(options[:batch]).each do |section|
        section.sync_sis_assignments
      end
    else
      RequestSisAssignmentsJob.perform_later ids: Section.all.pluck(:id)
    end
  end
end