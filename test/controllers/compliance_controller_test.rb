require "test_helper"

class ComplianceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
  end

  test "requires authentication" do
    get compliance_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows non-compliant batches for the user's own organization" do
    Batch.create!(lot_number: "LOT-BAD", temperature_celsius: 15, vehicle: @vehicle, organization: @organization)
    other_org = Organization.create!(name: "Other Org")
    other_vehicle = Vehicle.create!(name: "Truck 2", organization: other_org)
    Batch.create!(lot_number: "LOT-OTHER", temperature_celsius: 15, vehicle: other_vehicle, organization: other_org)

    sign_in @user
    get compliance_url

    assert_response :success
    assert_select "td", text: "LOT-BAD"
    assert_select "td", text: "LOT-OTHER", count: 0
  end

  test "shows the organization's real audit trail" do
    Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    AuditLog.record!(event: "batch_created", user: @user)

    sign_in @user
    get compliance_url

    assert_response :success
    assert_select "td", text: "Batch created"
  end
end
