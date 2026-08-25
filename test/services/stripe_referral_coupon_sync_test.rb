require "test_helper"

class StripeReferralCouponSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates the coupon when it doesn't exist yet" do
    not_found = Stripe::InvalidRequestError.new("No such coupon", "id", code: "resource_missing")
    fake_coupon = Stripe::Coupon.construct_from(id: "referral-free-month", percent_off: 100, duration: "once")

    create_params = nil
    Stripe::Coupon.stub :retrieve, ->(*) { raise not_found } do
      Stripe::Coupon.stub :create, ->(params) { create_params = params; fake_coupon } do
        result = StripeReferralCouponSync.call
        assert_equal fake_coupon, result
      end
    end

    assert_equal "referral-free-month", create_params[:id]
    assert_equal 100, create_params[:percent_off]
    assert_equal "once", create_params[:duration]
  end

  test "reuses the existing coupon instead of creating a duplicate" do
    existing = Stripe::Coupon.construct_from(id: "referral-free-month", percent_off: 100, duration: "once")

    Stripe::Coupon.stub :retrieve, existing do
      Stripe::Coupon.stub :create, ->(*) { raise "should not create a second coupon" } do
        result = StripeReferralCouponSync.call
        assert_equal existing, result
      end
    end
  end
end
