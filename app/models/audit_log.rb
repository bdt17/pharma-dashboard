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
end
