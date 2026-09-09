require "test_helper"

class BatchTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
  end

  def build_batch(temperature_celsius: 5)
    Batch.create!(lot_number: "LOT-#{SecureRandom.hex(4)}", temperature_celsius: temperature_celsius, vehicle: @vehicle, organization: @organization)
  end

  test "a new batch has no lot_number pre-filled -- the stale DB default is gone" do
    assert_nil Batch.new.lot_number
  end

  test "requires a lot_number now that the DB default no longer masks a blank one" do
    batch = Batch.new(vehicle: @vehicle, organization: @organization, lot_number: "")
    assert_not batch.valid?
    assert_includes batch.errors[:lot_number], "can't be blank"
  end

  test "requires a vehicle" do
    batch = Batch.new(lot_number: "LOT-1", organization: @organization)
    assert_not batch.valid?
    assert_includes batch.errors[:vehicle], "must exist"
  end

  test "a new batch defaults to active status" do
    assert_equal "active", build_batch.status
  end

  test "an explicit status passed at creation is not overridden" do
    batch = Batch.create!(lot_number: "LOT-#{SecureRandom.hex(4)}", vehicle: @vehicle, organization: @organization, status: "delivered")
    assert_equal "delivered", batch.status
  end

  test "lot_number must be unique" do
    Batch.create!(lot_number: "LOT-DUPE", vehicle: @vehicle, organization: @organization)
    dupe = Batch.new(lot_number: "LOT-DUPE", vehicle: @vehicle, organization: @organization)

    assert_not dupe.valid?
    assert_includes dupe.errors[:lot_number], "has already been taken"
  end

  test "compliance_status is unknown with no temperature recorded, compliant/non-compliant otherwise" do
    assert_equal "unknown", build_batch(temperature_celsius: nil).compliance_status
    assert_equal "compliant", build_batch(temperature_celsius: 5).compliance_status
    assert_equal "non-compliant", build_batch(temperature_celsius: 15).compliance_status
  end

  test "non_compliant scope excludes both compliant batches and ones with no reading" do
    compliant = build_batch(temperature_celsius: 5)
    non_compliant = build_batch(temperature_celsius: 15)
    unknown = build_batch(temperature_celsius: nil)

    result = Batch.non_compliant
    assert_includes result, non_compliant
    assert_not_includes result, compliant
    assert_not_includes result, unknown
  end

  test "temperature_excursions only includes telemetry readings outside the compliant range" do
    batch = build_batch
    in_range = batch.telemetries.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0, temp: 5.0)
    out_of_range = batch.telemetries.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0, temp: 12.0)
    no_reading = batch.telemetries.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0)

    excursions = batch.temperature_excursions
    assert_includes excursions, out_of_range
    assert_not_includes excursions, in_range
    assert_not_includes excursions, no_reading
  end

  test "temperature_excursions only includes readings linked to this batch, not other telemetry from the same vehicle" do
    batch = build_batch
    other_batch = build_batch
    linked = batch.telemetries.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0, temp: 12.0)
    other_batch.telemetries.create!(vehicle: @vehicle, lat: 33.4, lng: -112.0, temp: 12.0)
    @vehicle.telemetries.create!(lat: 33.4, lng: -112.0, temp: 12.0) # no batch link at all

    assert_equal [ linked ], batch.temperature_excursions.to_a
  end
end
