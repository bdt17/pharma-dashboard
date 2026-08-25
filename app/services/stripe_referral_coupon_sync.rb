# One-time-per-setup script (not something a request path calls): ensures
# the reusable "referral free month" Stripe Coupon exists -- 100% off,
# applied once -- so ReferralReward has something real to attach to a
# subscription. Same idea as StripeAnnualPriceSync/StripeAddonPriceSync,
# just for a Coupon instead of a Price. Run via
# `bin/rails stripe:sync_referral_coupon`.
class StripeReferralCouponSync
  COUPON_ID = "referral-free-month".freeze

  def self.call
    new.call
  end

  def call
    Stripe::Coupon.retrieve(COUPON_ID)
  rescue Stripe::InvalidRequestError
    Stripe::Coupon.create(id: COUPON_ID, percent_off: 100, duration: "once", name: "Referral free month")
  end
end
