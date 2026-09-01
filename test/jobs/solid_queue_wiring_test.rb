require "test_helper"

# The rest of the suite runs on the :test adapter (set by rails/test_help).
# This one flips to the real :solid_queue adapter to prove the wiring is
# intact: an enqueued job is persisted to solid_queue_jobs and made ready
# for a worker to claim. Executing it is Solid Queue's own (well-tested)
# job -- what this guards is that the gem, the migration, and the adapter
# config actually line up.
class SolidQueueWiringTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class EchoJob < ApplicationJob
    queue_as :default
    def perform(value)
      Rails.logger.info("EchoJob: #{value}")
    end
  end

  setup do
    @previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue
    SolidQueue::Job.delete_all
  end

  teardown do
    ActiveJob::Base.queue_adapter = @previous_adapter
    SolidQueue::Job.delete_all
  end

  test "an enqueued job is persisted and marked ready for a worker" do
    EchoJob.perform_later("hello")

    job = SolidQueue::Job.find_by(class_name: EchoJob.name)
    assert job, "expected the job to be written to solid_queue_jobs"
    assert_equal "default", job.queue_name
    assert SolidQueue::ReadyExecution.exists?(job_id: job.id),
      "expected a ready execution so a worker can claim it"
  end

  test "a job scheduled for later is not immediately ready" do
    EchoJob.set(wait: 1.hour).perform_later("later")

    job = SolidQueue::Job.find_by(class_name: EchoJob.name)
    assert job.scheduled_at.present?
    assert_not SolidQueue::ReadyExecution.exists?(job_id: job.id)
    assert SolidQueue::ScheduledExecution.exists?(job_id: job.id)
  end
end
