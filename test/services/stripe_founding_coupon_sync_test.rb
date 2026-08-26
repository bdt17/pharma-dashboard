require "test_helper"

class StripeFoundingCouponSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates the coupon when it doesn't exist yet" do
    not_found = Stripe::InvalidRequestError.new("No such coupon", "id", code: "resource_missing")
    fake_coupon = Stripe::Coupon.construct_from(id: StripeFoundingCouponSync::COUPON_ID, percent_off: 25, duration: "repeating", duration_in_months: 6)

    create_params = nil
    Stripe::Coupon.stub :retrieve, ->(*) { raise not_found } do
      Stripe::Coupon.stub :create, ->(params) { create_params = params; fake_coupon } do
        result = StripeFoundingCouponSync.call
        assert_equal fake_coupon, result
      end
    end

    assert_equal StripeFoundingCouponSync::COUPON_ID, create_params[:id]
    assert_equal 25, create_params[:percent_off]
    assert_equal "repeating", create_params[:duration]
    assert_equal 6, create_params[:duration_in_months]
    assert_equal StripeBilling.founding_offer_cutoff.to_i, create_params[:redeem_by]
    # Stripe rejects Coupon#name over 40 characters -- caught live the
    # first time this task actually ran (a 43-character name), so this
    # guards against that regressing silently again.
    assert create_params[:name].length <= 40, "name is #{create_params[:name].length} chars, Stripe's limit is 40"
  end

  test "reuses the existing coupon instead of creating a duplicate" do
    existing = Stripe::Coupon.construct_from(id: StripeFoundingCouponSync::COUPON_ID, percent_off: 25, duration: "repeating")

    Stripe::Coupon.stub :retrieve, existing do
      Stripe::Coupon.stub :create, ->(*) { raise "should not create a second coupon" } do
        result = StripeFoundingCouponSync.call
        assert_equal existing, result
      end
    end
  end
end
