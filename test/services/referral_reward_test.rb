require "test_helper"

class ReferralRewardTest < ActiveSupport::TestCase
  setup do
    @referrer = Organization.create!(name: "Referring Pharmacy")
    @referred = Organization.create!(name: "New Pharmacy")
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "does nothing when there's no referral for this organization" do
    Stripe::Subscription.stub :update, ->(*) { raise "should not be called" } do
      assert_nothing_raised { ReferralReward.grant_for!(organization: @referred) }
    end
  end

  test "applies the coupon to the referred organization's own subscription regardless of the referrer" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    Subscription.create!(organization: @referred, status: "active", stripe_subscription_id: "sub_referred")

    calls = []
    Stripe::Subscription.stub :update, ->(id, params) { calls << [ id, params ] } do
      ReferralReward.grant_for!(organization: @referred)
    end

    assert_equal [ [ "sub_referred", { coupon: "referral-free-month" } ] ], calls
    assert_not_nil Referral.find_by(referred_organization: @referred).rewarded_at
  end

  test "also rewards the referrer when they have an active subscription" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    Subscription.create!(organization: @referred, status: "active", stripe_subscription_id: "sub_referred")
    Subscription.create!(organization: @referrer, status: "active", stripe_subscription_id: "sub_referrer")

    calls = []
    Stripe::Subscription.stub :update, ->(id, params) { calls << id } do
      ReferralReward.grant_for!(organization: @referred)
    end

    assert_includes calls, "sub_referred"
    assert_includes calls, "sub_referrer"
  end

  test "does not reward the referrer when they have no active subscription" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    Subscription.create!(organization: @referred, status: "active", stripe_subscription_id: "sub_referred")

    calls = []
    Stripe::Subscription.stub :update, ->(id, params) { calls << id } do
      ReferralReward.grant_for!(organization: @referred)
    end

    assert_equal [ "sub_referred" ], calls
  end

  test "is a no-op the second time -- an already-rewarded referral is not touched again" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred, rewarded_at: 1.day.ago)
    Subscription.create!(organization: @referred, status: "active", stripe_subscription_id: "sub_referred")

    Stripe::Subscription.stub :update, ->(*) { raise "should not be called" } do
      assert_nothing_raised { ReferralReward.grant_for!(organization: @referred) }
    end
  end

  test "logs and continues if applying the coupon raises a Stripe error" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    Subscription.create!(organization: @referred, status: "active", stripe_subscription_id: "sub_referred")

    Stripe::Subscription.stub :update, ->(*) { raise Stripe::InvalidRequestError.new("boom", nil) } do
      assert_nothing_raised do
        ReferralReward.grant_for!(organization: @referred)
      end
    end

    assert_not_nil Referral.find_by(referred_organization: @referred).rewarded_at
  end
end
