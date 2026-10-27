require "test_helper"

class CustodyLogsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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

  test "recording a delivery enqueues the auto Compliance Packet job" do
    sign_in @driver

    assert_enqueued_with(job: GenerateDeliveryPacketJob) do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "delivered", handler_name: "Jane Doe", location: "Phoenix, AZ", signature_data: signature_params }
      }
    end
    assert_equal [ CustodyLog.last.id, @driver.id ], enqueued_jobs.last[:args]
  end

  test "a non-delivery custody event does not enqueue the packet job" do
    sign_in @driver

    assert_no_enqueued_jobs only: GenerateDeliveryPacketJob do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end
  end

  test "recording a delivery advances the batch's own status to delivered" do
    sign_in @driver
    assert_equal "active", @batch.reload.status

    post batch_custody_logs_url(@batch), params: {
      custody_log: { action_type: "delivered", handler_name: "Jane Doe", location: "Phoenix, AZ", signature_data: signature_params }
    }

    assert_equal "delivered", @batch.reload.status
  end

  test "a non-delivery custody event leaves the batch's status alone" do
    sign_in @driver

    post batch_custody_logs_url(@batch), params: {
      custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
    }

    assert_equal "active", @batch.reload.status
  end

  test "recording a custody event fires the custody.recorded webhook on the Compliance plan" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_c", tier: "compliance")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/hook")
    sign_in @driver

    assert_enqueued_jobs 1, only: WebhookDeliveryJob do
      post batch_custody_logs_url(@batch), params: {
        custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ" }
      }
    end
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

  test "driver mode: GPS, temperature, and the signed-in recorder are saved; blank location falls back to GPS" do
    sign_in @driver
    post batch_custody_logs_url(@batch), params: {
      custody_log: { action_type: "pickup", handler_name: "Jane Doe", location: "",
                     latitude: "33.448376", longitude: "-112.074036", location_accuracy_m: "12", temperature_celsius: "4.6" }
    }

    log = CustodyLog.last
    assert_equal @driver, log.recorded_by
    assert_equal BigDecimal("33.448376"), log.latitude
    assert_equal BigDecimal("-112.074036"), log.longitude
    assert_equal 12, log.location_accuracy_m
    assert_equal BigDecimal("4.6"), log.temperature_celsius
    assert_equal "GPS 33.44838, -112.07404 (±12 m)", log.location

    get batch_custody_log_url(@batch, log)
    assert_match "4.6 °C", response.body
    assert_match "openstreetmap.org", response.body
  end

  test "the submitted recorder can't be spoofed" do
    other = User.create!(email: "other@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    sign_in @driver
    post batch_custody_logs_url(@batch), params: {
      custody_log: { action_type: "pickup", handler_name: "Jane", location: "Phoenix", recorded_by_id: other.id }
    }
    assert_equal @driver, CustodyLog.last.recorded_by
  end

  test "an out-of-range temperature or half a coordinate is rejected" do
    sign_in @driver
    assert_no_difference -> { CustodyLog.count } do
      post batch_custody_logs_url(@batch), params: { custody_log: { action_type: "pickup", handler_name: "J", location: "P", temperature_celsius: "470" } }
    end
    assert_response :unprocessable_content

    assert_no_difference -> { CustodyLog.count } do
      post batch_custody_logs_url(@batch), params: { custody_log: { action_type: "pickup", handler_name: "J", location: "P", latitude: "33.4" } }
    end
    assert_response :unprocessable_content
  end

  test "only the record-custody form may ask for the device location" do
    sign_in @driver
    get new_batch_custody_log_url(@batch)
    assert_match "geolocation=(self)", response.headers["Permissions-Policy"]
    assert_match "camera=()", response.headers["Permissions-Policy"]

    get batch_custody_logs_url(@batch)
    assert_match "geolocation=()", response.headers["Permissions-Policy"]
  end

  test "the form defaults to pickup, then delivery once picked up, and honors a preset action" do
    sign_in @driver
    get new_batch_custody_log_url(@batch)
    assert_select "input[type=radio][value=pickup][checked]"
    assert_select "input[name=?][value=?]", "custody_log[handler_name]", "driver@example.com"

    CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "J", location: "P")
    get new_batch_custody_log_url(@batch)
    assert_select "input[type=radio][value=delivered][checked]"

    get new_batch_custody_log_url(@batch, action_type: "exception")
    assert_select "input[type=radio][value=exception][checked]"
    get new_batch_custody_log_url(@batch, action_type: "bogus")
    assert_select "input[type=radio][value=delivered][checked]"
  end
end
