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
    CustodyLog.create!(batch: @batch, action_type: "handoff", handler_name: "Jane", location: "Tucson, AZ", timestamp: 1.hour.from_now)
    CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "Jane", location: "Phoenix, AZ", timestamp: 2.hours.ago)

    sign_in @driver
    get batch_custody_logs_url(@batch)

    assert_response :success
    assert_select "td", text: "Phoenix, AZ"
  end

  def signature_params
    { image: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
      signer_name: "John Recipient", signer_role: "recipient" }
  end

  test "a delivered event with a real signature is accepted and stamped with server-side metadata" do
    sign_in @driver

    post batch_custody_logs_url(@batch), params: {
      custody_log: { action_type: "delivered", handler_name: "Jane Doe", location: "Phoenix, AZ", signature_data: signature_params }
    }

    log = CustodyLog.last
    assert log.signed?
    assert_equal "John Recipient", log.signature_data["signer_name"]
    assert log.signature_data["signed_at"].present?, "signed_at should be stamped server-side"
    assert log.signature_data["ip_address"].present?, "ip_address should be stamped server-side"
  end

  test "a delivered event with no signature is rejected with a real error, not a 500" do
    sign_in @driver

    assert_no_difference -> { CustodyLog.count } do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "delivered", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end

    assert_response :unprocessable_content
    assert_match "must include a signature", response.body
  end

  test "a non-delivery event doesn't need a signature" do
    sign_in @driver

    assert_difference -> { CustodyLog.count }, 1 do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end

    assert_not CustodyLog.last.signed?
  end
end
