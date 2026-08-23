# The pricing-metering half of the Compliance Packet feature: an
# organization without an active (or trialing) subscription can generate a
# limited number of formal Compliance Packets per calendar month, enough to
# actually try the feature on a real shipment, not enough to run real
# cold-chain operations on for free. Subscribing removes the cap entirely --
# this is the thing being sold, not a separate "plan tier" system layered on
# top of it. Deliberately doesn't try to map Stripe plan names/amounts to
# different quota tiers: pricing is never hardcoded in this app (see
# StripeBilling), and "subscribed or not" is the one distinction that
# doesn't require guessing at plan-naming conventions that live in Stripe's
# own dashboard, not here.
class ComplianceReportQuota
  FREE_MONTHLY_LIMIT = 3

  def initialize(organization)
    @organization = organization
  end

  # nil means "no cap" (an active/trialing subscription) -- distinct from 0,
  # which means "capped, and the cap is used up."
  def remaining
    return nil if unlimited?

    [ FREE_MONTHLY_LIMIT - used_this_month, 0 ].max
  end

  def exceeded?
    !unlimited? && used_this_month >= FREE_MONTHLY_LIMIT
  end

  def unlimited?
    subscription&.active_or_trialing? || false
  end

  private

  attr_reader :organization

  def subscription
    organization&.subscriptions&.order(created_at: :desc)&.first
  end

  def used_this_month
    organization.compliance_reports.where(created_at: Time.current.beginning_of_month..).count
  end
end
