class SyncCanvasEnrollmentsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = if args.any?
                args.first
              else
                {}
              end

    if options[:id]
      Course.find(options[:id]).enroll_users_in_canvas
    elsif options[:ids]
      slice_size = (options[:ids].size / 10.0).ceil
      begin
        options[:ids].each_slice(slice_size) do |ids|
          SyncCanvasEnrollmentsJob.perform_later batch: ids
        end
      rescue
        raise "Invalid Slice Size: #{slice_size}"
      end
    elsif options[:batch]
      Course.find(options[:batch]).each do |course|
        course.enroll_users_in_canvas
      end
    else
      SyncCanvasEnrollmentsJob.perform_later ids: Course.where(sync_course: true).pluck(:id)
      if options[:repeat]
        SyncCanvasEnrollmentsJob.set(wait: 1.minute).perform_later repeat: true
      end
    end
  end
end