# Applies the "1 free month for both sides" referral reward once the
# referred organization's own subscription first goes active -- not at
# signup, so a code can't be farmed by creating accounts that never pay.
# Called from StripeWebhooksController when a customer.subscription.*
# event reports status "active".
#
# The referred organization's reward is unconditional (they just proved
# they're a real paying customer, by definition, in the same event that
# triggers this). The referrer's reward is best-effort: it only applies if
# the referrer currently has their own active/trialing subscription to
# discount -- there's nothing to give a free month off of otherwise, and
# this deliberately doesn't try to bank a credit for later, to keep the
# reward mechanism to "apply a Stripe coupon to a real subscription"
# rather than a second ledger alongside ReportCredit.
class ReferralReward
  def self.grant_for!(organization:)
    new(organization).grant!
  end

  def initialize(organization)
    @organization = organization
  end

  def grant!
    referral = Referral.pending.find_by(referred_organization: organization)
    return unless referral

    apply_coupon_to!(organization)
    apply_coupon_to!(referral.referrer_organization) if unlimited?(referral.referrer_organization)
    referral.update!(rewarded_at: Time.current)
  end

  private

  attr_reader :organization

  def unlimited?(org)
    latest_subscription(org)&.active_or_trialing? || false
  end

  def apply_coupon_to!(org)
    subscription = latest_subscription(org)
    return unless subscription&.stripe_subscription_id

    Stripe::Subscription.update(subscription.stripe_subscription_id, coupon: StripeReferralCouponSync::COUPON_ID)
  rescue Stripe::StripeError => e
    Rails.logger.error("ReferralReward: failed to apply coupon for organization #{org.id}: #{e.class}: #{e.message}")
  end

  def latest_subscription(org)
    org.subscriptions.order(created_at: :desc).first
  end
end
