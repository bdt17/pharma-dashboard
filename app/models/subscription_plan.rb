# The canonical definition of the three subscription tiers. One place that
# the Stripe sync task, ComplianceReportQuota, the pricing page, and the
# Billing page all read from -- Stripe still holds the authoritative Price
# objects (see StripeBilling / StripeSubscriptionPlansSync), but the tier
# name, the monthly amount used when creating those Prices, the per-month
# Compliance Packet allowance, and the marketing feature list live here.
#
# `packet_allowance` nil means unlimited. `tier` is the string stored on
# Subscription#tier (synced from the Stripe Price's `tier` metadata) and
# used by ComplianceReportQuota.
module SubscriptionPlan
  Plan = Data.define(:tier, :name, :monthly_cents, :packet_allowance, :tagline, :features) do
    def monthly_dollars = monthly_cents / 100
    def unlimited_packets? = packet_allowance.nil?
  end

  STARTER = Plan.new(
    tier: "starter",
    name: "Starter",
    monthly_cents: 9_900,
    packet_allowance: 15,
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
    tagline: "For a pharmacy that wants the deadline handled, not managed.",
    features: [
      "Everything in Pro",
      "Unlimited Compliance Packets",
      "A quarterly compliance review call",
      "20% off the fractional compliance officer retainer"
    ]
  )

  ALL = [ STARTER, PRO, COMPLIANCE ].freeze

  def self.find(tier)
    ALL.find { |plan| plan.tier == tier }
  end

  def self.tiers
    ALL.map(&:tier)
  end
end
