# Real webhook signature verification, ready to point Stripe at as soon as
# real API keys and a webhook secret are configured -- but no live
# checkout/charge code ships alongside it (see the Phase 5 PR description
# for why: that needs a real Stripe account this repo doesn't have).
#
# Until STRIPE_WEBHOOK_SECRET is set, every request here fails signature
# verification and is rejected -- the safe default, not "accept anything."
class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event = verified_event
    return unless event

    case event.type
    when "customer.subscription.created", "customer.subscription.updated"
      sync_subscription(event.data.object)
    when "customer.subscription.deleted"
      cancel_subscription(event.data.object)
    when "checkout.session.completed"
      grant_report_credit(event.data.object)
    end

    head :ok
  end

  private

  def verified_event
    Stripe::Webhook.construct_event(
      request.body.read,
      request.headers["Stripe-Signature"],
      ENV["STRIPE_WEBHOOK_SECRET"]
    )
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("StripeWebhooksController: rejected event (#{e.class}: #{e.message})")
    head :bad_request
    nil
  end

  def sync_subscription(stripe_subscription)
    organization = Organization.find_by(stripe_customer_id: stripe_subscription.customer)
    unless organization
      Rails.logger.warn("StripeWebhooksController: no organization for customer #{stripe_subscription.customer}")
      return
    end

    # As of Stripe API version 2025-11-17.clover, current_period_end lives
    # on each subscription item rather than on the Subscription itself --
    # a subscription can have multiple items, each billed on its own
    # period. Reproduced live: every real checkout crashed this handler
    # with NoMethodError, since Stripe::Subscription no longer responds to
    # current_period_end at all. This app only ever creates single-item
    # subscriptions, so the first item is authoritative for both the price
    # and the period end.
    item = stripe_subscription.items.data.first

    Subscription.sync_from_stripe!(
      organization: organization,
      stripe_subscription_id: stripe_subscription.id,
      status: stripe_subscription.status,
      plan_amount: item&.price ? item.price.unit_amount / 100.0 : nil,
      current_period_end: item&.current_period_end ? Time.at(item.current_period_end) : nil
    )

    # "active" specifically, not "trialing" -- a referral reward only pays
    # out once this organization has actually converted to a real paying
    # customer, not merely started a (card-required-but-not-yet-charged)
    # trial. ReferralReward itself is the idempotency guard: it's a no-op
    # once a referral's already been rewarded.
    ReferralReward.grant_for!(organization: organization) if stripe_subscription.status == "active"
  end

  def cancel_subscription(stripe_subscription)
    Subscription.find_by(stripe_subscription_id: stripe_subscription.id)&.update!(status: "canceled")
  end

  # Only a Compliance-Packet-credit add-on (single or bulk) completes
  # checkout this way (mode: "payment" with this specific metadata -- see
  # StripeBilling.start_addon_checkout!/addon_metadata_for); an ordinary
  # subscription checkout also fires checkout.session.completed, and so
  # does the White-Glove Setup service, which has nothing to grant here --
  # a real person fulfills that after seeing the payment in Stripe.
  def grant_report_credit(session)
    return unless session.mode == "payment" && session.metadata&.[]("kind") == "compliance_report_credit"

    organization = Organization.find_by(stripe_customer_id: session.customer)
    unless organization
      Rails.logger.warn("StripeWebhooksController: no organization for customer #{session.customer}")
      return
    end

    quantity = session.metadata["credit_quantity"].to_i
    quantity = 1 if quantity < 1

    if quantity == 1
      ReportCredit.grant!(organization: organization, stripe_checkout_session_id: session.id)
    else
      ReportCredit.grant_batch!(organization: organization, stripe_checkout_session_id: session.id, quantity: quantity)
    end
  end
end
