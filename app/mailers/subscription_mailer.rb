# Payment-recovery ("dunning") email. Goes to the organization's admins --
# the only people who can act on billing -- when a subscription charge has
# failed and Stripe is retrying. Sent by Subscription#send_dunning_email!,
# once on the transition into `past_due` and then on a cadence from
# DunningSweepJob.
class SubscriptionMailer < ApplicationMailer
  # Heads-up that the saved card is about to expire, sent once per card by
  # CardExpiryCheckJob. `card` is { last4:, exp_month:, exp_year: }.
  def card_expiring(organization, card)
    @organization = organization
    @card = card
    @expires = format("%02d/%d", card[:exp_month], card[:exp_year])

    mail(
      to: recipients,
      subject: "The card on file for #{organization.name} expires soon"
    )
  end

  def payment_failed(subscription)
    @subscription = subscription
    @organization = subscription.organization
    @plan = subscription.plan
    @amount = subscription.plan_amount
    # Only worth showing if it's still ahead of us -- once the period end
    # has passed, Stripe is in its retry grace window and the date is just
    # confusing.
    @period_end = subscription.current_period_end if subscription.current_period_end&.future?

    mail(
      to: recipients,
      subject: "Your Pharma Transport payment didn't go through"
    )
  end

  private

  def recipients
    emails = @organization.users.where(role: "admin").pluck(:email)
    emails.presence || [ self.class.default[:from] ]
  end
end
