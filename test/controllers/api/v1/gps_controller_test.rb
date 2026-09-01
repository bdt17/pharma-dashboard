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
