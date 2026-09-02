require "test_helper"

class Api::V1::GpsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization, imei: "123456789012345")
  end

  test "rejects a request with no token" do
    post api_v1_gps_url, params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0 }
    assert_response :unauthorized
  end

  test "rejects a request with the wrong token" do
    post api_v1_gps_url,
      params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0 },
      headers: { "X-Device-Token" => "wrong-token" }
    assert_response :unauthorized
  end

  test "rejects a request for an unknown imei" do
    post api_v1_gps_url,
      params: { imei: "000000000000000", lat: 33.4, lng: -112.0 },
      headers: { "X-Device-Token" => @vehicle.api_token }
    assert_response :unauthorized
  end

  test "accepts a request with the correct token and records a telemetry reading" do
    assert_difference -> { Telemetry.count }, 1 do
      post api_v1_gps_url,
        params: { imei: @vehicle.imei, lat: 33.4484, lng: -112.0740, speed: 45, temp: 5.2 },
        headers: { "X-Device-Token" => @vehicle.api_token }
    end

    assert_response :created
    telemetry = Telemetry.last
    assert_equal @vehicle, telemetry.vehicle
    assert_in_delta 33.4484, telemetry.lat, 0.0001
    assert_in_delta 5.2, telemetry.temp, 0.0001
  end

  def post_reading(extra = {})
    post api_v1_gps_url,
      params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0, temp: 5.0 }.merge(extra),
      headers: { "X-Device-Token" => @vehicle.api_token }
  end

  test "honours a captured_at timestamp (ISO-8601) for a buffered reading" do
    taken = 40.minutes.ago.change(usec: 0)
    post_reading(captured_at: taken.iso8601)

    assert_response :created
    assert_in_delta taken, Telemetry.last.recorded_at, 1.second
  end

  test "honours a captured_at timestamp given as a Unix epoch" do
    taken = 2.hours.ago.change(usec: 0)
    post_reading(captured_at: taken.to_i.to_s)

    assert_in_delta taken, Telemetry.last.recorded_at, 1.second
  end

  test "falls back to the receive time when captured_at is absent, unparseable, or out of range" do
    [ nil, "not-a-time", 10.days.ago.iso8601, 1.hour.from_now.iso8601 ].each do |value|
      assert_difference -> { Telemetry.count }, 1 do
        post_reading(value.nil? ? {} : { captured_at: value })
      end
      assert_response :created
      assert_in_delta Time.current, Telemetry.last.recorded_at, 5.seconds, "value=#{value.inspect}"
    end
  end

  test "a buffered (backdated) reading does not drag the vehicle snapshot backwards" do
    post_reading(lat: 34.0, lng: -118.0)                 # a fresh reading
    fresh_ping = @vehicle.reload.last_ping_at

    post_reading(lat: 10.0, lng: 10.0, captured_at: 30.minutes.ago.iso8601)  # a late flush

    @vehicle.reload
    assert_equal fresh_ping, @vehicle.last_ping_at, "last_ping_at should not move backwards"
    assert_in_delta 34.0, @vehicle.latitude, 0.001, "position should still be the fresh reading's"
  end

  test "attributes the reading to the vehicle's current undelivered batch" do
    Batch.create!(lot_number: "LOT-DONE", vehicle: @vehicle, organization: @organization, status: "delivered")
    current = Batch.create!(lot_number: "LOT-LIVE", vehicle: @vehicle, organization: @organization, status: "active")

    post api_v1_gps_url,
      params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0, temp: 5.0 },
      headers: { "X-Device-Token" => @vehicle.api_token }

    assert_response :created
    assert_equal current, Telemetry.last.batch
  end

  test "an out-of-range reading on the current batch raises a temperature-excursion alert" do
    User.create!(email: "admin@acme.test", password: "password123!", organization: @organization, role: "admin")
    Batch.create!(lot_number: "LOT-LIVE", vehicle: @vehicle, organization: @organization, status: "active")

    assert_enqueued_emails 1 do
      post api_v1_gps_url,
        params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0, temp: 14.0 },
        headers: { "X-Device-Token" => @vehicle.api_token }
    end

    assert_response :created
    assert ExcursionEvent.ongoing.exists?
  end

  test "does not require a Devise session -- this is device auth, not user auth" do
    post api_v1_gps_url,
      params: { imei: @vehicle.imei, lat: 33.4, lng: -112.0 },
      headers: { "X-Device-Token" => @vehicle.api_token }
    assert_response :created
  end
end
