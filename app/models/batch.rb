class Batch < ApplicationRecord
  COMPLIANT_RANGE = (2..8)

  # Required, matching the DB's NOT NULL constraint on vehicle_id -- the
  # model used to say optional: true, which was never actually true
  # (nothing ever created a batch without one by hand), just undetected
  # because nothing but hand-built records exercised it. Left as-is it
  # would have surfaced as a raw ActiveRecord::NotNullViolation from the
  # self-serve creation form instead of a readable validation error.
  belongs_to :vehicle
  belongs_to :driver, class_name: "User", inverse_of: :driven_batches, optional: true
  belongs_to :organization
  has_many :audit_logs, dependent: :nullify
  has_many :custody_logs, -> { order(:timestamp) }, dependent: :destroy
  has_many :compliance_reports, -> { order(:version) }, dependent: :restrict_with_error
  # Only readings explicitly linked to this batch (Telemetry#batch_id) --
  # not "everything this vehicle ever recorded," which would mix in other
  # deliveries. Api::V1::GpsController#create sets it from
  # vehicle.current_batch on every ingested reading.
  has_many :telemetries, -> { order(:recorded_at) }, dependent: :nullify
  # Derived monitoring data -- rebuilt from telemetry, safe to drop with
  # the batch (unlike compliance_reports, which are issued records).
  has_many :excursion_events, dependent: :destroy

  # Global, not scoped to organization -- matches the existing DB unique
  # index (added before multi-tenancy). Two unrelated pharmacies could in
  # theory collide on a lot number; revisit (with a migration to a
  # compound [organization_id, lot_number] index) if that ever actually
  # happens. Validated here so a collision is a readable form error
  # instead of a raw ActiveRecord::RecordNotUnique.
  validates :lot_number, presence: true, uniqueness: true
  # Intentionally *not* validated into the compliant range: a temperature
  # excursion is exactly the event this system exists to detect and record.
  # Rejecting the save would make it impossible to ever have a record of a
  # real cold-chain breach. Numericality just guards against garbage input.
  validates :temperature_celsius, numericality: true, allow_nil: true

  before_validation :default_status, on: :create

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

  private

  # A newly created batch is presumed to be a shipment about to move, not
  # already delivered -- see Vehicle#current_batch, which is exactly this
  # check in reverse. Only fills in a blank so a caller that passes an
  # explicit status (seeds, tests, an eventual bulk-import path) isn't
  # overridden.
  def default_status
    self.status ||= "active"
  end
end
