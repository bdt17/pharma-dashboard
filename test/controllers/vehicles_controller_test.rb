require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
  end

  test "new requires authentication" do
    get new_vehicle_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "a driver cannot reach the new vehicle form" do
    sign_in @driver
    get new_vehicle_url
    assert_redirected_to root_path
  end

  test "an admin can register a vehicle and gets its device token shown once" do
    sign_in @admin

    assert_difference "Vehicle.count", 1 do
      post vehicles_url, params: { vehicle: { name: "Truck 4", imei: "860000000000099", plate: "ABC-123" } }
    end

    vehicle = Vehicle.last
    assert_equal @organization, vehicle.organization
    assert_equal "860000000000099", vehicle.imei
    assert_redirected_to edit_vehicle_path(vehicle)
    follow_redirect!
    assert_select "code", text: vehicle.api_token
  end

  test "a dispatcher can also register a vehicle" do
    sign_in @dispatcher

    assert_difference "Vehicle.count", 1 do
      post vehicles_url, params: { vehicle: { name: "Van 1" } }
    end
  end

  test "the device token is not shown again on a plain revisit" do
    sign_in @admin
    vehicle = Vehicle.create!(name: "Truck 4", organization: @organization)

    get edit_vehicle_url(vehicle)
    assert_response :success
    assert_select "code", text: vehicle.api_token, count: 0
  end

  test "imei is optional -- a vehicle can be registered without one" do
    sign_in @admin

    assert_difference "Vehicle.count", 1 do
      post vehicles_url, params: { vehicle: { name: "Truck 5" } }
    end
    assert_nil Vehicle.last.imei
  end

  test "a malformed imei is rejected with a readable error" do
    sign_in @admin

    assert_no_difference "Vehicle.count" do
      post vehicles_url, params: { vehicle: { name: "Truck 6", imei: "not-an-imei" } }
    end
    assert_response :unprocessable_content
    assert_match "15 digits", response.body
  end

  test "a duplicate imei is rejected" do
    Vehicle.create!(name: "Existing", organization: @organization, imei: "860000000000001")
    sign_in @admin

    assert_no_difference "Vehicle.count" do
      post vehicles_url, params: { vehicle: { name: "Truck 7", imei: "860000000000001" } }
    end
    assert_response :unprocessable_content
    assert_match "has already been taken", response.body
  end

  test "a blank name is rejected" do
    sign_in @admin

    assert_no_difference "Vehicle.count" do
      post vehicles_url, params: { vehicle: { name: "" } }
    end
    assert_response :unprocessable_content
  end

  test "an admin can edit and update their own organization's vehicle" do
    sign_in @admin
    vehicle = Vehicle.create!(name: "Truck 4", organization: @organization)

    patch vehicle_url(vehicle), params: { vehicle: { name: "Truck Four", imei: "860000000000002", plate: "XYZ-999" } }
    assert_redirected_to edit_vehicle_path(vehicle)
    vehicle.reload
    assert_equal "Truck Four", vehicle.name
    assert_equal "860000000000002", vehicle.imei
  end

  test "a driver cannot update a vehicle" do
    sign_in @driver
    vehicle = Vehicle.create!(name: "Truck 4", organization: @organization)

    patch vehicle_url(vehicle), params: { vehicle: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_equal "Truck 4", vehicle.reload.name
  end

  test "a user cannot edit another organization's vehicle" do
    other_org = Organization.create!(name: "Other Pharma")
    other_vehicle = Vehicle.create!(name: "Their Truck", organization: other_org)
    sign_in @admin

    get edit_vehicle_url(other_vehicle)
    assert_response :not_found
  end
end
