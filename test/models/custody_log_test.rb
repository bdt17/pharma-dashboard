require "test_helper"

class CustodyLogTest < ActiveSupport::TestCase
  setup do
    organization = Organization.create!(name: "Acme Pharma")
    vehicle = Vehicle.create!(name: "Truck 1", organization: organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: vehicle, organization: organization)
  end

  test "requires action_type, handler_name, and location" do
    log = CustodyLog.new(batch: @batch)
    assert_not log.valid?
    assert_includes log.errors[:action_type], "can't be blank"
    assert_includes log.errors[:handler_name], "can't be blank"
    assert_includes log.errors[:location], "can't be blank"
  end

  test "rejects an action_type outside the defined set" do
    log = CustodyLog.new(batch: @batch, action_type: "teleported", handler_name: "Jane", location: "Phoenix, AZ")
    assert_not log.valid?
    assert_includes log.errors[:action_type], "is not included in the list"
  end

  test "defaults timestamp to now on create" do
    log = CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "Jane", location: "Phoenix, AZ")
    assert_in_delta Time.current, log.timestamp, 5.seconds
  end

  test "batch.custody_logs is ordered by timestamp" do
    later = CustodyLog.create!(batch: @batch, action_type: "delivered", handler_name: "Jane", location: "Tucson, AZ", timestamp: 1.hour.from_now)
    earlier = CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "Jane", location: "Phoenix, AZ", timestamp: 2.hours.ago)

    assert_equal [ earlier, later ], @batch.custody_logs.to_a
  end
end
