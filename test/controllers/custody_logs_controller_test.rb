require "test_helper"

class CustodyLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization, driver: @driver)
  end

  test "the assigned driver can record a custody event" do
    sign_in @driver

    assert_difference -> { CustodyLog.count }, 1 do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end

    assert_redirected_to batch_custody_log_url(@batch, CustodyLog.last)
  end

  test "recording a custody event writes an audit log entry" do
    sign_in @driver

    assert_difference -> { AuditLog.count }, 1 do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end

    assert_equal "custody_log_created", AuditLog.last.event
  end

  test "a user from another organization who isn't the driver cannot record a custody event" do
    outsider = User.create!(email: "outsider@example.com", password: "password123!", organization: Organization.create!(name: "Other Org"), role: "admin")
    sign_in outsider

    assert_no_difference -> { CustodyLog.count } do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end
  end

  test "index lists custody events for the batch, oldest first" do
    CustodyLog.create!(batch: @batch, action_type: "delivered", handler_name: "Jane", location: "Tucson, AZ", timestamp: 1.hour.from_now)
    CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "Jane", location: "Phoenix, AZ", timestamp: 2.hours.ago)

    sign_in @driver
    get batch_custody_logs_url(@batch)

    assert_response :success
    assert_select "td", text: "Phoenix, AZ"
  end
end
