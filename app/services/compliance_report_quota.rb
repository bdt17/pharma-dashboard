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
#
# An organization can also buy a single extra Compliance Packet outside a
# subscription (see ReportCredit) -- a purchased credit only ever covers a
# generation once the free monthly allowance is already used up, so it
# never gets silently burned by a month that still had free room left.
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

  # False whenever a generation is actually allowed right now: unlimited,
  # still within the free monthly allowance, or -- beyond that -- a
  # purchased credit is available to spend. See credit_to_consume for which
  # of those three reasons applies to the generation about to happen.
  def exceeded?
    return false if unlimited?
    return false if used_this_month < FREE_MONTHLY_LIMIT

    available_credit.nil?
  end

  def unlimited?
    subscription&.active_or_trialing? || false
  end

  # The credit ComplianceReportsController should spend for the report
  # about to be generated, or nil if this generation is covered by the
  # subscription or the free monthly allowance and no credit should be
  # touched.
  def credit_to_consume
    return nil if unlimited? || used_this_month < FREE_MONTHLY_LIMIT

    available_credit
  end

  private

  attr_reader :organization

  def available_credit
    organization.report_credits.available.order(:created_at).first
  end

  def subscription
    organization&.subscriptions&.order(created_at: :desc)&.first
  end

  def used_this_month
    organization.compliance_reports.where(created_at: Time.current.beginning_of_month..).count
  end
end
