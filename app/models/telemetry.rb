# A single GPS/sensor reading from a vehicle's tracking device. This is the
# one canonical position/telemetry table (see the Phase 1 audit for the four
# redundant tables it replaces) -- an append-only time series, never
# updated or deleted after creation.
class Telemetry < ApplicationRecord
  belongs_to :vehicle
  belongs_to :batch, optional: true

  validates :lat, :lng, presence: true, numericality: true
  validates :temp, numericality: true, allow_nil: true
  validates :speed, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :set_recorded_at, on: :create

  after_create_commit :update_vehicle_snapshot
  after_create_commit :monitor_excursion

  private

  # Cold-chain alerting: hand each reading to ExcursionMonitor, which opens
  # or closes the batch's ExcursionEvent and sends the alert email. Never
  # let an alerting failure turn into a failed GPS ingest -- the reading
  # itself is the source of truth and is already saved by this point.
  def monitor_excursion
    ExcursionMonitor.evaluate(self)
  rescue StandardError => e
    Rails.logger.error("[ExcursionMonitor] #{e.class}: #{e.message}")
  end

  def set_recorded_at
    self.recorded_at ||= Time.current
  end

  # Vehicle.latitude/longitude/speed/last_ping_at are a denormalized cache
  # of "where is this vehicle right now" so dashboard reads don't have to
  # scan telemetry history on every request. Telemetry itself remains the
  # full, real history.
  #
  # A reading older than what the snapshot already reflects -- a buffered
  # reading flushed after the device reconnected -- is kept in history but
  # must not drag the "where is it now" cache backwards.
  def update_vehicle_snapshot
    return if vehicle.last_ping_at && recorded_at && recorded_at < vehicle.last_ping_at

    vehicle.update_columns(
      latitude: lat,
      longitude: lng,
      speed: speed,
      last_ping_at: recorded_at
    )
  end
end
