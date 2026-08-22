require "test_helper"

class Api::V1::VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org_a = Organization.create!(name: "Org A")
    @org_b = Organization.create!(name: "Org B")
    @user_a = User.create!(email: "user-a@example.com", password: "password123!", organization: @org_a, role: "dispatcher")
    @vehicle_a = Vehicle.create!(name: "Truck A", organization: @org_a)
    @vehicle_b = Vehicle.create!(name: "Truck B", organization: @org_b)
  end

  test "index requires authentication" do
    get api_v1_vehicles_url
    assert_response :unauthorized
  end

  test "index only returns vehicles in the signed-in user's organization" do
    sign_in @user_a
    get api_v1_vehicles_url

    ids = JSON.parse(response.body).map { |v| v["id"] }
    assert_includes ids, @vehicle_a.id
    assert_not_includes ids, @vehicle_b.id
  end

  test "show returns real vehicle data" do
    Telemetry.create!(vehicle: @vehicle_a, lat: 33.4484, lng: -112.0740, speed: 45)

    sign_in @user_a
    get api_v1_vehicle_url(@vehicle_a)

    body = JSON.parse(response.body)
    assert_equal @vehicle_a.id, body["id"]
    assert_in_delta 33.4484, body["latitude"], 0.0001
  end

  test "show is forbidden for a vehicle in another organization" do
    sign_in @user_a
    get api_v1_vehicle_url(@vehicle_b)

    assert_response :forbidden
  end
end
