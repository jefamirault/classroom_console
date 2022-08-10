class BaseWorker
  include Sidekiq::Worker

  def perform(*args)
    SyncJob.perform_now
    BaseWorker.perform_in 1.minute
  end
end
