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

  private

  def set_recorded_at
    self.recorded_at ||= Time.current
  end

  # Vehicle.latitude/longitude/speed/last_ping_at are a denormalized cache
  # of "where is this vehicle right now" so dashboard reads don't have to
  # scan telemetry history on every request. Telemetry itself remains the
  # full, real history.
  def update_vehicle_snapshot
    vehicle.update_columns(
      latitude: lat,
      longitude: lng,
      speed: speed,
      last_ping_at: recorded_at
    )
  end
end
