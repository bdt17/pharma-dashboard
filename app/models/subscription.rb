class Subscription < ApplicationRecord
  belongs_to :organization

  # Mirrors Stripe's own subscription status vocabulary directly (minus a
  # couple of Stripe statuses -- incomplete/incomplete_expired -- that never
  # apply here since nothing creates a Subscription before Stripe confirms
  # it). Storing Stripe's own values means no translation layer to keep in
  # sync when webhook events come in.
  enum :status, {
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid"
  }, validate: true

  validates :stripe_subscription_id, uniqueness: true, allow_nil: true

  def active_or_trialing?
    active? || trialing?
  end

  # The one write path for applying a Stripe webhook event to our local
  # copy of subscription state -- see StripeWebhooksController. Idempotent:
  # replaying the same event (Stripe's own delivery guarantee is
  # at-least-once) just re-applies the same attributes.
  def self.sync_from_stripe!(organization:, stripe_subscription_id:, status:, plan_amount: nil, current_period_end: nil, tier: nil)
    subscription = find_or_initialize_by(stripe_subscription_id: stripe_subscription_id)
    subscription.organization = organization
    subscription.status = status
    subscription.plan_amount = plan_amount if plan_amount
    subscription.current_period_end = current_period_end if current_period_end
    subscription.tier = tier if tier
    subscription.save!
    subscription
  end

  # The SubscriptionPlan for this subscription's tier, or nil for a
  # subscription created before tiers (or on a Price with no `tier`
  # metadata) -- ComplianceReportQuota treats that nil as "unlimited",
  # preserving the pre-tier behaviour.
  def plan
    SubscriptionPlan.find(tier)
  end
end
