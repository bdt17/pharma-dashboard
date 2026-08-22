require "test_helper"

class TelemetryTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
  end

  test "requires lat and lng" do
    telemetry = Telemetry.new(vehicle: @vehicle)
    assert_not telemetry.valid?
    assert_includes telemetry.errors[:lat], "can't be blank"
    assert_includes telemetry.errors[:lng], "can't be blank"
  end

  test "batch is optional -- a ping doesn't require an active delivery" do
    telemetry = Telemetry.new(vehicle: @vehicle, lat: 33.4, lng: -112.0)
    assert telemetry.valid?
  end

  test "defaults recorded_at to now on create" do
    telemetry = Telemetry.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0)
    assert_in_delta Time.current, telemetry.recorded_at, 5.seconds
  end

  test "updates the vehicle's cached position snapshot" do
    Telemetry.create!(vehicle: @vehicle, lat: 33.4484, lng: -112.0740, speed: 45.5)

    @vehicle.reload
    assert_in_delta 33.4484, @vehicle.latitude, 0.0001
    assert_in_delta(-112.0740, @vehicle.longitude, 0.0001)
    assert_in_delta 45.5, @vehicle.speed, 0.0001
    assert_not_nil @vehicle.last_ping_at
  end
end
