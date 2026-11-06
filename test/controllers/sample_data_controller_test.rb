require "test_helper"

class SampleDataControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @org, role: "driver")
  end

  test "an empty account is offered sample data on the dashboard" do
    sign_in @admin
    get dashboard_url
    assert_select "form[action=?]", sample_data_path
  end

  test "loading shows the banner on every page and a clear button" do
    sign_in @admin
    post sample_data_url
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select "button", text: "Clear sample data"
    assert_match "You’re looking at sample data", response.body.gsub("&rsquo;", "’")

    get compliance_url
    assert_select "button", text: "Clear sample data"
    assert AuditLog.exists?(event: "sample_data_loaded")
  end

  test "sample batches refuse custody events, packets, and edits" do
    SampleData.load!(@org, user: @admin)
    batch = @org.batches.samples.first
    sign_in @admin

    get batch_custody_logs_url(batch)
    assert_select "a", text: "Record a custody event", count: 0
    assert_select ".badge", text: "Sample"

    assert_no_difference -> { CustodyLog.count } do
      post batch_custody_logs_url(batch), params: { custody_log: { action_type: "pickup", handler_name: "X", location: "Y" } }
    end
    assert_no_difference -> { ComplianceReport.count } do
      post batch_compliance_reports_url(batch)
    end
    get edit_batch_url(batch)
    assert_redirected_to root_path
  end

  test "sample vehicles are not offered for a real batch" do
    SampleData.load!(@org, user: @admin)
    sign_in @admin
    get new_batch_url
    assert_select "option", text: /Sample delivery/, count: 0

    sample_vehicle = @org.vehicles.samples.first
    assert_no_difference -> { Batch.count } do
      post batches_url, params: { batch: { lot_number: "LOT-9", vehicle_id: sample_vehicle.id } }
    end
  end

  test "clearing removes the samples and the banner" do
    SampleData.load!(@org, user: @admin)
    sign_in @admin
    delete sample_data_url
    assert_redirected_to dashboard_path
    assert_not @org.reload.sample_data?
    follow_redirect!
    assert_select "button", text: "Clear sample data", count: 0
  end

  test "drivers can't load or clear sample data" do
    sign_in @driver
    post sample_data_url
    assert_not @org.reload.sample_data?

    SampleData.load!(@org, user: @admin)
    delete sample_data_url
    assert @org.reload.sample_data?
  end
end
