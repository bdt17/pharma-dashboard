require "test_helper"

class DeliveryGpsPrecisionTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @batch = Batch.create!(lot_number: "LOT-1", vehicle: Vehicle.create!(name: "Van", organization: @org), organization: @org)
  end

  def record(action, **attrs)
    CustodyLog.create!(batch: @batch, action_type: action, handler_name: "Sam", latitude: 33.448376, longitude: -112.074036,
                       location_accuracy_m: 9, **attrs,
                       signature_data: action == "delivered" ? { "image" => DemoData::TINY_PNG, "signer_name" => "Pat" } : nil)
  end

  test "new organizations default to approximate" do
    assert_equal "approximate", @org.delivery_gps_precision
  end

  test "approximate rounds a delivery to about 1 km and fills a blank location with it" do
    log = record("delivered")
    assert_equal 33.45, log.latitude.to_f
    assert_equal(-112.07, log.longitude.to_f)
    assert_equal 1_100, log.location_accuracy_m
    assert_equal "GPS 33.45, -112.07 (±1100 m)", log.location
  end

  test "off drops the fix on a delivery, so a location must be typed" do
    @org.update!(delivery_gps_precision: "off")
    assert_raises(ActiveRecord::RecordInvalid) { record("delivered") }

    log = record("delivered", location: "Patient residence")
    assert_nil log.latitude
    assert_nil log.longitude
    assert_nil log.location_accuracy_m
  end

  test "exact keeps the fix" do
    @org.update!(delivery_gps_precision: "exact")
    assert_equal 33.448376, record("delivered").latitude.to_f
  end

  test "pickups always keep the exact fix" do
    @org.update!(delivery_gps_precision: "off")
    log = record("pickup")
    assert_equal 33.448376, log.latitude.to_f
    assert_equal 9, log.location_accuracy_m
  end

  test "only the listed settings are valid" do
    @org.delivery_gps_precision = "street"
    assert_not @org.valid?
  end
end
