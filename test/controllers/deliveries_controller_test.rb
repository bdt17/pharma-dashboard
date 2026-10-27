require "test_helper"

class DeliveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    @other_driver = User.create!(email: "driver2@example.com", password: "password123!", organization: @organization, role: "driver")
    @dispatcher = User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @mine = Batch.create!(lot_number: "LOT-MINE", vehicle: @vehicle, organization: @organization, driver: @driver)
    @theirs = Batch.create!(lot_number: "LOT-THEIRS", vehicle: @vehicle, organization: @organization, driver: @other_driver)
    @done = Batch.create!(lot_number: "LOT-DONE", vehicle: @vehicle, organization: @organization, driver: @driver, status: "delivered")
    other_org = Organization.create!(name: "Other Rx")
    Batch.create!(lot_number: "LOT-FOREIGN", vehicle: Vehicle.create!(name: "T", organization: other_org), organization: other_org)
  end

  test "requires authentication" do
    get deliveries_url
    assert_redirected_to new_user_session_url
  end

  test "a driver sees only their own undelivered shipments, with pickup first" do
    sign_in @driver
    get deliveries_url
    assert_response :success
    assert_match "LOT-MINE", response.body
    assert_no_match "LOT-THEIRS", response.body
    assert_no_match "LOT-DONE", response.body
    assert_no_match "LOT-FOREIGN", response.body
    assert_select "a[href=?]", new_batch_custody_log_path(@mine, action_type: "pickup")

    CustodyLog.create!(batch: @mine, action_type: "pickup", handler_name: "J", location: "Store")
    get deliveries_url
    assert_select "a[href=?]", new_batch_custody_log_path(@mine, action_type: "delivered")
  end

  test "a dispatcher sees every active shipment in their organization" do
    sign_in @dispatcher
    get deliveries_url
    assert_match "LOT-MINE", response.body
    assert_match "LOT-THEIRS", response.body
    assert_no_match "LOT-FOREIGN", response.body
  end

  test "a driver lands on their deliveries after sign-in, with a driver-only menu" do
    sign_in @driver
    get root_url
    assert_redirected_to deliveries_path
    follow_redirect!
    assert_select "aside a[href=?]", billing_path, count: 0
    assert_select "aside a[href=?]", deliveries_path

    sign_in @dispatcher
    get root_url
    assert_redirected_to dashboard_path
  end
end
