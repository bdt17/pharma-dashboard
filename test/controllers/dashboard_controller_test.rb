require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
  end

  test "requires authentication" do
    get dashboard_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows real counts and cross-organization data stays out" do
    Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    Batch.create!(lot_number: "LOT-BAD", temperature_celsius: 15, vehicle: @vehicle, organization: @organization)

    other_org = Organization.create!(name: "Other Org")
    other_vehicle = Vehicle.create!(name: "Truck 2", organization: other_org)
    Batch.create!(lot_number: "LOT-OTHER", temperature_celsius: 5, vehicle: other_vehicle, organization: other_org)

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_select "td", text: "LOT-BAD"
    assert_select "td", text: "LOT-OTHER", count: 0
  end

  test "shows recent custody events for the organization" do
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    batch.custody_logs.create!(action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ")

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_match "Phoenix, AZ", response.body
    assert_match "pickup", response.body
  end
end
