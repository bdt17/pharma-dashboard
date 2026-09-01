require "test_helper"

class DunningSweepJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  def failing_subscription(count:, last_at:, status: "past_due")
    Subscription.create!(
      organization: @organization, stripe_subscription_id: "sub_#{SecureRandom.hex(4)}",
      status: status, dunning_email_count: count, last_dunning_email_at: last_at
    )
  end

  test "sends a follow-up for a subscription whose interval has elapsed" do
    sub = failing_subscription(count: 1, last_at: (Subscription::DUNNING_INTERVAL + 1.hour).ago)

    assert_enqueued_emails 1 do
      DunningSweepJob.perform_now
    end
    assert_equal 2, sub.reload.dunning_email_count
  end

  test "skips a subscription still inside its interval" do
    failing_subscription(count: 1, last_at: 1.hour.ago)

    assert_no_enqueued_emails do
      DunningSweepJob.perform_now
    end
  end

  test "stops at the cap" do
    failing_subscription(count: Subscription::DUNNING_MAX_EMAILS, last_at: 1.month.ago)

    assert_no_enqueued_emails do
      DunningSweepJob.perform_now
    end
  end

  test "ignores active subscriptions" do
    Subscription.create!(organization: @organization, stripe_subscription_id: "sub_ok", status: "active")

    assert_no_enqueued_emails do
      DunningSweepJob.perform_now
    end
  end

  test "picks up a failing subscription that never got a first email" do
    sub = failing_subscription(count: 0, last_at: nil, status: "unpaid")

    assert_enqueued_emails 1 do
      DunningSweepJob.perform_now
    end
    assert_equal 1, sub.reload.dunning_email_count
  end
end
