# The pricing-metering half of the Compliance Packet feature.
#
# - No active subscription: a small free allowance per calendar month
#   (FREE_MONTHLY_LIMIT), enough to try the feature on a real shipment.
# - Starter / Pro: the per-month allowance for that tier
#   (SubscriptionPlan#packet_allowance).
# - Compliance tier, or a legacy subscription with no tier: unlimited.
#
# Beyond whichever cap applies, an organization can spend a purchased
# ReportCredit (single or bulk) -- a credit only ever covers a generation
# once the monthly allowance is already used up, so it never gets silently
# burned by a month that still had room left.
class ComplianceReportQuota
  FREE_MONTHLY_LIMIT = 3

  def initialize(organization)
    @organization = organization
  end

  # nil means "no cap" -- distinct from 0, which means "capped, and the cap
  # is used up".
  def remaining
    return nil if unlimited?

    [ monthly_allowance - used_this_month, 0 ].max
  end

  # False whenever a generation is actually allowed right now: unlimited,
  # still within the monthly allowance, or -- beyond that -- a purchased
  # credit is available to spend.
  def exceeded?
    return false if unlimited?
    return false if used_this_month < monthly_allowance

    available_credit.nil?
  end

  # An active/trialing subscription whose tier has no packet allowance
  # (the Compliance tier, or a pre-tier subscription).
  def unlimited?
    return false unless subscribed?

    plan.nil? || plan.unlimited_packets?
  end

  # The credit ComplianceReportsController should spend for the report
  # about to be generated, or nil if this generation is covered by the
  # subscription/free allowance and no credit should be touched.
  def credit_to_consume
    return nil if unlimited? || used_this_month < monthly_allowance

    available_credit
  end

  # The number a "limit reached" message should quote.
  def monthly_allowance
    return FREE_MONTHLY_LIMIT unless subscribed?

    plan&.packet_allowance || FREE_MONTHLY_LIMIT
  end

  # True when a generation right now would be billed as an overage rather
  # than blocked: the organization is on a capped paid tier (Starter /
  # Pro), has used its monthly allowance with no purchased credit left,
  # has opted in to overage billing, and has a Stripe customer to invoice.
  # Unlimited tiers never reach here (nothing to exceed); the free tier
  # never does either (no subscription) -- overage is only for paying
  # customers who chose it.
  def overage_billable?
    return false unless capped_plan?
    return false unless organization.overage_billing_enabled?
    return false if organization.stripe_customer_id.blank?
    return false if used_this_month < monthly_allowance

    available_credit.nil?
  end

  private

  attr_reader :organization

  def subscribed?
    subscription&.active_or_trialing? || false
  end

  # A paying tier with a finite monthly allowance -- Starter or Pro.
  def capped_plan?
    subscribed? && plan&.packet_allowance.present?
  end

  def plan
    subscription&.plan
  end

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
