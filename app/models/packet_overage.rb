# One billed "extra Compliance Packet" -- a packet a capped-plan
# organization generated past its monthly allowance after opting in to
# overage billing (Organization#overage_billing_enabled). Append-only,
# the same way ReportCredit is: one row per ComplianceReport (unique
# index), so a retried generation request can't bill the customer twice.
#
# The charge itself is a *pending* Stripe invoice item created by
# StripeBilling.add_packet_overage_item! -- it lands on the organization's
# next subscription invoice, with no immediate card charge.
class PacketOverage < ApplicationRecord
  belongs_to :organization
  belongs_to :compliance_report

  validates :stripe_invoice_item_id, presence: true
  validates :amount_cents, presence: true

  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..) }

  # Records the ledger row for an overage whose Stripe invoice item has
  # already been created (see ComplianceReportsController#create).
  # Idempotent on the compliance report.
  def self.record!(organization:, compliance_report:, invoice_item:)
    find_or_create_by!(compliance_report_id: compliance_report.id) do |overage|
      overage.organization = organization
      overage.stripe_invoice_item_id = invoice_item[:invoice_item_id]
      overage.amount_cents = invoice_item[:amount_cents]
      overage.currency = invoice_item[:currency]
    end
  end
end
