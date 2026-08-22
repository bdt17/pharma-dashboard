class Batch < ApplicationRecord
  COMPLIANT_RANGE = (2..8)

  belongs_to :vehicle, optional: true
  belongs_to :driver, class_name: "User", inverse_of: :driven_batches, optional: true
  belongs_to :organization
  has_many :audit_logs, dependent: :nullify
  has_many :custody_logs, -> { order(:timestamp) }, dependent: :destroy

  validates :lot_number, presence: true
  # Intentionally *not* validated into the compliant range: a temperature
  # excursion is exactly the event this system exists to detect and record.
  # Rejecting the save would make it impossible to ever have a record of a
  # real cold-chain breach. Numericality just guards against garbage input.
  validates :temperature_celsius, numericality: true, allow_nil: true

  scope :compliant, -> { where(temperature_celsius: COMPLIANT_RANGE) }
  scope :active, -> { where(status: "active") }

  def compliance_status
    return "unknown" if temperature_celsius.nil?

    COMPLIANT_RANGE.cover?(temperature_celsius) ? "compliant" : "non-compliant"
  end

  def self.to_csv
    require "csv"
    attributes = %w[id lot_number vehicle_id temperature_celsius status created_at]
    CSV.generate(headers: true) do |csv|
      all.each do |batch|
        csv << batch.attributes.values_at(*attributes)
      end
    end
  end
end
