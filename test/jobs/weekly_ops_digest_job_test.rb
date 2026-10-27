require "test_helper"
require "fugit"

class WeeklyOpsDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "sends the digest" do
    assert_emails 1 do
      WeeklyOpsDigestJob.perform_now
    end
  end

  test "is scheduled for Monday 8am Phoenix in production" do
    task = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "weekly_ops_digest")
    assert_equal "WeeklyOpsDigestJob", task["class"]

    cron = Fugit.parse(task["schedule"])
    assert_equal "0 8 * * 1 America/Phoenix", cron.to_cron_s
  end
end
