class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :batch, optional: true

  validates :event, presence: true

  # Plain words for the event codes, shown to customers. Anything not
  # listed falls back to the humanized code ("team_member_invited" ->
  # "Team member invited"), so a new event never shows up blank.
  EVENT_LABELS = {
    "custody_log_created" => "Custody event recorded",
    "compliance_report_generated" => "Compliance Packet generated",
    "compliance_packet_autogen_skipped" => "Compliance Packet skipped (monthly limit reached)",
    "chain_of_custody_pdf_generated" => "Chain-of-custody PDF downloaded",
    "sample_data_loaded" => "Sample data loaded",
    "sample_data_cleared" => "Sample data cleared",
    "team_invitation_accepted" => "Invitation accepted",
    "signed_out_other_sessions" => "Signed out other devices",
    "two_factor_reset" => "Two-factor reset",
    "delivery_gps_precision_changed" => "Delivery location precision changed"
  }.freeze

  def event_label
    EVENT_LABELS.fetch(event) { event.to_s.humanize }
  end

  # The one write path for audit entries, so every caller records the same
  # shape consistently instead of hand-building AuditLog.create! calls with
  # slightly different fields each time.
  def self.record!(event:, user:, batch: nil, ip_address: nil, data: {})
    create!(event: event, user: user, batch: batch, ip_address: ip_address, data: data)
  end

  # Same pattern as Batch.to_csv: a class method so it can be called on an
  # already-scoped relation too (organization-scoped audit logs, an
  # explicit .order) and still operate on that scope, not the whole
  # table -- Rails delegates it back through .scoping. `data` is the raw
  # per-event JSON (shape varies by event type -- see the call sites in
  # AuditLog.record!), included verbatim rather than flattened, since an
  # auditor pulling this file wants the detail, not a summary.
  def self.to_csv
    require "csv"
    CSV.generate(headers: true) do |csv|
      csv << [ "Time", "Event", "User", "IP address", "Batch lot number", "Data" ]
      all.each do |log|
        csv << CsvSafe.row([
          log.created_at.iso8601,
          log.event,
          log.user.email,
          log.ip_address,
          log.batch&.lot_number,
          log.data.presence&.to_json
        ])
      end
    end
  end
end
