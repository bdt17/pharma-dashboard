require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  test "rejects a status outside Stripe's own vocabulary" do
    subscription = Subscription.new(organization: @organization, status: "made_up_status")
    assert_not subscription.valid?
    assert_includes subscription.errors[:status], "is not included in the list"
  end

  test "active_or_trialing? is true for active and trialing, false otherwise" do
    assert Subscription.new(status: "active").active_or_trialing?
    assert Subscription.new(status: "trialing").active_or_trialing?
    assert_not Subscription.new(status: "canceled").active_or_trialing?
    assert_not Subscription.new(status: "past_due").active_or_trialing?
  end

  test "payment_failing? is true for past_due and unpaid, false otherwise" do
    assert Subscription.new(status: "past_due").payment_failing?
    assert Subscription.new(status: "unpaid").payment_failing?
    assert_not Subscription.new(status: "active").payment_failing?
    assert_not Subscription.new(status: "trialing").payment_failing?
    assert_not Subscription.new(status: "canceled").payment_failing?
  end

  test ".sync_from_stripe! creates a new subscription" do
    subscription = Subscription.sync_from_stripe!(
      organization: @organization,
      stripe_subscription_id: "sub_123",
      status: "active",
      plan_amount: 99.0,
      current_period_end: Time.zone.parse("2027-01-01")
    )

    assert subscription.persisted?
    assert_equal @organization, subscription.organization
    assert_equal "active", subscription.status
    assert_equal 99.0, subscription.plan_amount
  end

  test ".sync_from_stripe! stores the tier and exposes it as a plan" do
    subscription = Subscription.sync_from_stripe!(
      organization: @organization, stripe_subscription_id: "sub_t", status: "active", tier: "pro"
    )

    assert_equal "pro", subscription.tier
    assert_equal SubscriptionPlan::PRO, subscription.plan
  end

  test "#plan is nil for a subscription with no tier" do
    assert_nil Subscription.new.plan
  end

  test ".sync_from_stripe! is idempotent -- replaying the same event updates, not duplicates" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "trialing")

    assert_no_difference -> { Subscription.count } do
      Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active")
    end

    assert_equal "active", Subscription.find_by(stripe_subscription_id: "sub_123").status
  end

  # --- dunning / payment-recovery email ---

  class DunningTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    setup do
      @organization = Organization.create!(name: "Acme Pharma")
      User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    end

    def sync(status)
      Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_1", status: status)
    end

    test "transitioning into past_due sends the first recovery email and records it" do
      sync("active")

      assert_enqueued_emails 1 do
        sync("past_due")
      end

      sub = Subscription.find_by(stripe_subscription_id: "sub_1")
      assert_equal 1, sub.dunning_email_count
      assert sub.last_dunning_email_at
    end

    test "replayed past_due webhooks don't re-send the first email" do
      sync("active")
      sync("past_due")

      assert_no_enqueued_emails do
        3.times { sync("past_due") }
      end
      assert_equal 1, Subscription.find_by(stripe_subscription_id: "sub_1").dunning_email_count
    end

    test "recovering to active clears the dunning state" do
      sync("active")
      sync("past_due")
      sync("active")

      sub = Subscription.find_by(stripe_subscription_id: "sub_1")
      assert_equal 0, sub.dunning_email_count
      assert_nil sub.last_dunning_email_at
    end

    test "dunning_email_due? respects the interval, the cap, and the status" do
      sub = Subscription.create!(organization: @organization, stripe_subscription_id: "s", status: "past_due")

      assert sub.dunning_email_due?, "no email sent yet"

      sub.update!(dunning_email_count: 1, last_dunning_email_at: 1.day.ago)
      assert_not sub.dunning_email_due?, "within the interval"

      sub.update!(last_dunning_email_at: (Subscription::DUNNING_INTERVAL + 1.hour).ago)
      assert sub.dunning_email_due?, "interval elapsed"

      sub.update!(dunning_email_count: Subscription::DUNNING_MAX_EMAILS)
      assert_not sub.dunning_email_due?, "cap reached"

      sub.update!(dunning_email_count: 1, status: "active")
      assert_not sub.dunning_email_due?, "no longer failing"
    end
  end
end
