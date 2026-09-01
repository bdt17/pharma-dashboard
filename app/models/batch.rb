class Batch < ApplicationRecord
  COMPLIANT_RANGE = (2..8)

  belongs_to :vehicle, optional: true
  belongs_to :driver, class_name: "User", inverse_of: :driven_batches, optional: true
  belongs_to :organization
  has_many :audit_logs, dependent: :nullify
  has_many :custody_logs, -> { order(:timestamp) }, dependent: :destroy
  has_many :compliance_reports, -> { order(:version) }, dependent: :restrict_with_error
  # Only readings explicitly linked to this batch (Telemetry#batch_id) --
  # not "everything this vehicle ever recorded," which would mix in other
  # deliveries. Nothing currently sets batch_id when ingesting GPS/sensor
  # data (see Api::V1::GpsController#create), so this is empty until that
  # gap is closed; the compliance packet says so honestly rather than
  # falling back to a broader, misleading query.
  has_many :telemetries, -> { order(:recorded_at) }, dependent: :nullify
  # Derived monitoring data -- rebuilt from telemetry, safe to drop with
  # the batch (unlike compliance_reports, which are issued records).
  has_many :excursion_events, dependent: :destroy

  validates :lot_number, presence: true
  # Intentionally *not* validated into the compliant range: a temperature
  # excursion is exactly the event this system exists to detect and record.
  # Rejecting the save would make it impossible to ever have a record of a
  # real cold-chain breach. Numericality just guards against garbage input.
  validates :temperature_celsius, numericality: true, allow_nil: true

  scope :compliant, -> { where(temperature_celsius: COMPLIANT_RANGE) }
  scope :non_compliant, -> { where.not(temperature_celsius: nil).where.not(temperature_celsius: COMPLIANT_RANGE) }
  scope :active, -> { where(status: "active") }

  def compliance_status
    return "unknown" if temperature_celsius.nil?

    COMPLIANT_RANGE.cover?(temperature_celsius) ? "compliant" : "non-compliant"
  end

  # Telemetry readings for this batch that fall outside the compliant
  # range -- the real, time-series basis for "temperature excursion,"
  # distinct from compliance_status above (which only ever reflects the
  # single most recent snapshot on the batch itself).
  def temperature_excursions
    telemetries.where.not(temp: nil).where.not(temp: COMPLIANT_RANGE)
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
