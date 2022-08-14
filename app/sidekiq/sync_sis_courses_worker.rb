class SyncSisCoursesWorker
  include Sidekiq::Worker

  def perform(*args)
    SyncSisCoursesJob.perform_now
    # SyncSisCoursesWorker.perform_in 1.minute
  end
end
