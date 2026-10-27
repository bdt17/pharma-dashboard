# Sends the Monday operator digest. Scheduled in config/recurring.yml.
class WeeklyOpsDigestJob < ApplicationJob
  queue_as :default

  def perform
    OpsDigestMailer.weekly.deliver_now
  end
end
