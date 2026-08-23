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
  end

  def cancel_subscription(stripe_subscription)
    Subscription.find_by(stripe_subscription_id: stripe_subscription.id)&.update!(status: "canceled")
  end
end
