# Warns an organization's admins when the card on file for their
# subscription is about to expire, so a renewal doesn't silently fail into
# the dunning flow. Runs daily (see config/recurring.yml).
#
# Stripe has no reliable "card expiring" webhook for PaymentMethod-based
# subscriptions, so this polls: for each customer with a live subscription
# it reads the default card's expiry and emails once per card (tracked by
# Organization#card_expiry_notified_for). Replacing the card changes the
# expiry, which lifts the guard on its own.
class CardExpiryCheckJob < ApplicationJob
  queue_as :default

  # A card counts as "expiring soon" once it will have expired within this
  # window -- comfortably more than one monthly cycle, so there's time to
  # act before the next renewal.
  LEAD_TIME = 45.days

  def perform
    return unless StripeBilling.configured?

    Organization.where.not(stripe_customer_id: [ nil, "" ]).find_each do |organization|
      next unless subscribed?(organization)

      card = StripeBilling.default_card_for(organization)
      next unless card && expiring_soon?(card)

      period = format("%04d-%02d", card[:exp_year], card[:exp_month])
      next if organization.card_expiry_notified_for == period

      SubscriptionMailer.card_expiring(organization, card).deliver_later
      organization.update!(card_expiry_notified_for: period)
    end
  end

  private

  def subscribed?(organization)
    organization.subscriptions.order(created_at: :desc).first&.active_or_trialing? || false
  end

  def expiring_soon?(card)
    Date.new(card[:exp_year], card[:exp_month], 1).end_of_month <= LEAD_TIME.from_now.to_date
  rescue ArgumentError
    false
  end
end
