class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :batch, optional: true

  validates :event, presence: true

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
        csv << [
          log.created_at.iso8601,
          log.event,
          log.user.email,
          log.ip_address,
          log.batch&.lot_number,
          log.data.presence&.to_json
        ]
      end
    end
  end
end
