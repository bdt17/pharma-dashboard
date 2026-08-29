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
end
