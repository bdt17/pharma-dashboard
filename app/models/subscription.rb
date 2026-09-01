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

  # Payment-recovery email cadence: the first goes out the moment the
  # subscription starts failing (from the webhook), then DunningSweepJob
  # sends a follow-up every DUNNING_INTERVAL until the card is fixed or
  # DUNNING_MAX_EMAILS is reached (Stripe gives up and cancels after ~3
  # weeks, so 4 emails at 3-day spacing covers the whole window once).
  DUNNING_INTERVAL = 3.days
  DUNNING_MAX_EMAILS = 4

  def active_or_trialing?
    active? || trialing?
  end

  # Stripe is still retrying a failed charge (past_due) or has given up
  # short of canceling (unpaid). The organization has already lost its
  # packet allowance and verification badge at this point, so the app
  # surfaces a recovery prompt on every authenticated page -- see
  # layouts/_payment_recovery_banner.
  def payment_failing?
    past_due? || unpaid?
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
    subscription.handle_dunning_after_sync!
    subscription
  end

  # Run after every webhook sync. Kicks off the payment-recovery email the
  # first time a subscription starts failing, and clears the dunning state
  # once it's healthy again. Idempotent against Stripe's at-least-once
  # delivery: the `dunning_email_count.zero?` guard means replayed
  # "updated" events for an already-failing subscription do nothing here.
  def handle_dunning_after_sync!
    if active_or_trialing?
      reset_dunning!
    elsif payment_failing? && dunning_email_count.zero?
      send_dunning_email!
    end
  end

  # True when DunningSweepJob should send the next follow-up: still
  # failing, under the cap, and DUNNING_INTERVAL has passed since the last
  # one (or none has been sent yet).
  def dunning_email_due?
    return false unless payment_failing?
    return false if dunning_email_count >= DUNNING_MAX_EMAILS

    last_dunning_email_at.nil? || last_dunning_email_at <= DUNNING_INTERVAL.ago
  end

  def send_dunning_email!
    SubscriptionMailer.payment_failed(self).deliver_later
    update!(last_dunning_email_at: Time.current, dunning_email_count: dunning_email_count + 1)
  end

  # Back to a fresh slate so a future failure starts its own sequence.
  def reset_dunning!
    return if last_dunning_email_at.nil? && dunning_email_count.zero?

    update!(last_dunning_email_at: nil, dunning_email_count: 0)
  end

  # The SubscriptionPlan for this subscription's tier, or nil for a
  # subscription created before tiers (or on a Price with no `tier`
  # metadata) -- ComplianceReportQuota treats that nil as "unlimited",
  # preserving the pre-tier behaviour.
  def plan
    SubscriptionPlan.find(tier)
  end
end
