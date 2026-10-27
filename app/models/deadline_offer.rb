# Limited-time offer: subscribe (trial counts) by ENDS and White-Glove
# Setup -- normally a paid one-time add-on (see
# StripeWhiteGloveSetupPriceSync) -- is included free. Chosen over a
# discount because it leaves recurring revenue untouched and puts the
# operator on a call with every new customer, which is what turns an empty
# trial account into an active one.
#
# Originally tied to the DSCSA deadline; once the FDA extended that to
# 2027 (see DscsaDeadline) the offer got its own end date so it still
# means something this year.
#
# Fulfilment is manual: claim! stamps the organization and emails the
# operator; /ops lists who is owed a setup until it's marked done.
module DeadlineOffer
  ENDS = Date.new(2026, 12, 31)

  def self.active?(on: DscsaDeadline.today)
    on <= ENDS
  end

  def self.days_left(on: DscsaDeadline.today)
    [ (ENDS - on).to_i, 0 ].max
  end

  def self.label
    ENDS.strftime("%B %-d, %Y")
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
