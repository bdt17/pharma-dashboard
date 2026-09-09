require "test_helper"

class HeartbeatJobTest < ActiveJob::TestCase
  test "runs without error when Sentry is not configured" do
    assert_nothing_raised { HeartbeatJob.perform_now }
  end

  test "sends in-progress and ok check-ins to Sentry around perform" do
    calls = []
    Sentry.stub(:capture_check_in, ->(slug, status, **_kwargs) { calls << [ slug, status ]; nil }) do
      HeartbeatJob.perform_now
    end

    assert_equal %w[pharma-heartbeat pharma-heartbeat], calls.map(&:first)
    assert_equal %i[in_progress ok], calls.map(&:last)
  end

  test "is registered on a schedule" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"))
    assert_equal "HeartbeatJob", config.dig("production", "heartbeat", "class")
  end
end
