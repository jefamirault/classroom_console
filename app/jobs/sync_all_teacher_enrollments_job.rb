class SyncAllTeacherEnrollmentsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    User.where.not(sis_id: nil).each do |user|
      SyncTeacherEnrollmentsJob.perform_later user_id: user.id
    end
  end
end
