# One-time-per-setup script: ensures the "founding customer" launch-offer
# Stripe Coupon exists (25% off, repeating for 6 months, no longer
# redeemable after StripeBilling.founding_offer_cutoff). Same pattern as
# StripeReferralCouponSync. Run via
# `bin/rails stripe:sync_founding_coupon`.
class StripeFoundingCouponSync
  COUPON_ID = StripeBilling::FOUNDING_OFFER_COUPON_ID

  def self.call
    new.call
  end

  def call
    Stripe::Coupon.retrieve(COUPON_ID)
  rescue Stripe::InvalidRequestError
    Stripe::Coupon.create(
      id: COUPON_ID,
      percent_off: 25,
      duration: "repeating",
      duration_in_months: 6,
      redeem_by: StripeBilling.founding_offer_cutoff.to_i,
      # Stripe caps Coupon#name at 40 characters.
      name: "Founding customer: 25% off 6 months"
    )
  end
end
