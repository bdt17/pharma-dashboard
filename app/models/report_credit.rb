# One row per purchased "extra Compliance Packet" ($149 one-time, outside
# any subscription) -- see ComplianceReportQuota for how a credit gets
# spent and StripeWebhooksController for how one gets granted. Modeled the
# same way as ComplianceReport: an append-only ledger row rather than a
# bare counter on Organization, so a replayed Stripe webhook (Stripe's
# delivery guarantee is at-least-once) can't double-grant a purchase, and
# "how many credits has this org ever bought vs. actually used" stays a
# real, auditable history instead of one number that forgets its own past.
class ReportCredit < ApplicationRecord
  belongs_to :organization

  validates :stripe_checkout_session_id, presence: true, uniqueness: true

  scope :available, -> { where(consumed_at: nil) }

  # The one write path for granting a credit from a Stripe webhook --
  # idempotent on the checkout session id so a replayed
  # checkout.session.completed event can't grant the same $149 purchase
  # twice.
  def self.grant!(organization:, stripe_checkout_session_id:)
    find_or_create_by!(stripe_checkout_session_id: stripe_checkout_session_id) do |credit|
      credit.organization = organization
    end
  end

  # Marks this credit spent. ComplianceReportQuota#credit_to_consume is the
  # only intended caller, and it only ever hands out one available credit
  # at a time -- the lock+guard here just makes a double-call a no-op
  # instead of silently letting one purchase cover two report generations.
  def consume!
    with_lock do
      update!(consumed_at: Time.current) if consumed_at.nil?
    end
  end
end
