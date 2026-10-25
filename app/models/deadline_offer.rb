# Pre-deadline offer: subscribe (trial counts) before the DSCSA exemption
# ends and White-Glove Setup -- normally a paid one-time add-on (see
# StripeWhiteGloveSetupPriceSync) -- is included free. Chosen over a
# discount because it leaves recurring revenue untouched and puts the
# operator on a call with every new customer, which is what turns an empty
# trial account into an active one.
#
# Fulfilment is manual: claim! stamps the organization and emails the
# operator; /ops lists who is owed a setup until it's marked done.
module DeadlineOffer
  def self.active?(on: DscsaDeadline.today)
    !DscsaDeadline.passed?(on: on)
  end

  def self.value_label
    ActiveSupport::NumberHelper.number_to_currency(StripeWhiteGloveSetupPriceSync::AMOUNT_CENTS / 100, precision: 0)
  end

  # Called from the Stripe webhook whenever a subscription syncs as active
  # or trialing. Idempotent: only the first qualifying sync stamps and
  # emails, so Stripe's repeated "updated" events do nothing.
  def self.claim!(organization)
    return false unless active?
    return false if organization.free_setup_owed_at.present?

    organization.update!(free_setup_owed_at: Time.current)
    FreeSetupMailer.owed(organization).deliver_later
    true
  end
end
