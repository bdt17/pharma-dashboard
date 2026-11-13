require "test_helper"

# Fixes from a phone-width walk-through of the first-customer journey.
class JourneyUsabilityTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
  end

  test "a one-driver pharmacy gets its driver preselected on a new batch" do
    sam = User.create!(email: "sam@example.com", password: "password123!", organization: @org, role: "driver", name: "Sam")
    sign_in @admin
    get new_batch_path
    assert_select "select[name='batch[driver_id]'] option[selected][value=?]", sam.id.to_s
  end

  test "with two drivers nobody is preselected" do
    User.create!(email: "a@example.com", password: "password123!", organization: @org, role: "driver")
    User.create!(email: "b@example.com", password: "password123!", organization: @org, role: "driver")
    sign_in @admin
    get new_batch_path
    assert_select "select[name='batch[driver_id]'] option[selected]", count: 0
  end

  test "the exploring banner offers sample data right at the top" do
    post user_session_path, params: { user: { email: @admin.email, password: "password123!" } }
    get dashboard_path
    assert_select "form[action=?] button", sample_data_path, text: "Load sample data", minimum: 2
  end

  test "the dashboard's recent activity reads as plain words" do
    AuditLog.record!(event: "sample_data_loaded", user: @admin)
    sign_in @admin
    get dashboard_path
    assert_match "Sample data loaded", response.body
    assert_no_match ">sample_data_loaded<", response.body
  end

  test "the vehicle form says no tracker is needed" do
    sign_in @admin
    get new_vehicle_path
    assert_match "No tracker needed", response.body
  end
end
