# The canonical definition of the subscription tiers. One place that the
# Stripe sync task, ComplianceReportQuota, the pricing page, and the
# Billing page all read from -- Stripe still holds the authoritative Price
# objects (see StripeBilling / StripeSubscriptionPlansSync), but the tier
# name, the monthly amount used when creating those Prices, the per-month
# Compliance Packet allowance, and the marketing feature list live here.
#
# `packet_allowance` nil means unlimited. `tier` is the string stored on
# Subscription#tier (synced from the Stripe Price's `tier` metadata) and
# used by ComplianceReportQuota. `contact_sales` true means the tier is
# not offered as self-serve Checkout -- its Stripe Price still exists (so
# a subscription can be created for it by hand), but the pricing and
# billing pages point at the "talk to us" form instead of a Subscribe
# button.
module SubscriptionPlan
  Plan = Data.define(:tier, :name, :monthly_cents, :packet_allowance, :tagline, :features, :contact_sales) do
    def monthly_dollars = monthly_cents / 100
    def unlimited_packets? = packet_allowance.nil?
    def contact_sales? = contact_sales
  end

  STARTER = Plan.new(
    tier: "starter",
    name: "Starter",
    monthly_cents: 9_900,
    packet_allowance: 15,
    contact_sales: false,
    tagline: "The full record for a pharmacy moving product occasionally.",
    features: [
      "Live GPS fleet tracking",
      "Immutable hash-chained chain-of-custody log",
      "Proof-of-delivery signature capture",
      "Audit trail and compliance dashboard",
      "15 Compliance Packets per month",
      "Public DSCSA verification badge",
      "Unlimited team members",
      "Email support, one business day"
    ]
  )

  PRO = Plan.new(
    tier: "pro",
    name: "Pro",
    monthly_cents: 24_900,
    packet_allowance: 60,
    contact_sales: false,
    tagline: "For a pharmacy running regular cold-chain shipments.",
    features: [
      "Everything in Starter",
      "60 Compliance Packets per month",
      "A scheduled onboarding call",
      "Priority email support"
    ]
  )

  COMPLIANCE = Plan.new(
    tier: "compliance",
    name: "Compliance",
    monthly_cents: 49_900,
    packet_allowance: nil,
    contact_sales: false,
    tagline: "For a pharmacy that wants the deadline handled, not managed.",
    features: [
      "Everything in Pro",
      "Unlimited Compliance Packets",
      "A quarterly compliance review call",
      "20% off the fractional compliance officer retainer"
    ]
  )

  ENTERPRISE = Plan.new(
    tier: "enterprise",
    name: "Enterprise",
    monthly_cents: 149_900,
    packet_allowance: nil,
    contact_sales: true,
    tagline: "For a multi-location or specialty pharmacy that needs the deadline owned end to end.",
    features: [
      "Everything in Compliance",
      "A named compliance officer on retainer, included",
      "Priority audit support",
      "Custom SOP authoring for your operation",
      "Single sign-on (SAML)",
      "A dedicated account contact",
      "Onboarding and data migration handled for you"
    ]
  )

  ALL = [ STARTER, PRO, COMPLIANCE, ENTERPRISE ].freeze

  # The tiers a customer can subscribe to themselves through Stripe
  # Checkout -- everything except the contact-sales tiers.
  SELF_SERVE = ALL.reject(&:contact_sales).freeze

  def self.find(tier)
    ALL.find { |plan| plan.tier == tier }
  end

  def self.tiers
    ALL.map(&:tier)
  end

  def self.self_serve
    SELF_SERVE
  end
end
