require "test_helper"

class BatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "dispatcher@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
  end

  test "chain_of_custody requires authentication" do
    get batch_chain_of_custody_pdf_url(@batch), headers: html_accept
    assert_redirected_to new_user_session_url
  end

  test "chain_of_custody returns a real PDF for a batch in the user's organization" do
    sign_in @dispatcher
    get batch_chain_of_custody_pdf_url(@batch), headers: html_accept

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "expected a real PDF, got: #{response.body[0, 20].inspect}"
  end

  test "chain_of_custody records an audit log entry" do
    sign_in @dispatcher

    assert_difference -> { AuditLog.count }, 1 do
      get batch_chain_of_custody_pdf_url(@batch), headers: html_accept
    end

    log = AuditLog.last
    assert_equal "chain_of_custody_pdf_generated", log.event
    assert_equal @dispatcher, log.user
    assert_equal @batch, log.batch
  end

  test "chain_of_custody redirects away (does not serve the PDF) for a batch in a different organization" do
    other_org = Organization.create!(name: "Other Org")
    other_batch = Batch.create!(lot_number: "LOT-2", temperature_celsius: 5, vehicle: @vehicle, organization: other_org)

    sign_in @dispatcher
    get batch_chain_of_custody_pdf_url(other_batch), headers: html_accept

    assert_redirected_to root_url
  end

  test "new requires authentication" do
    get new_batch_url, headers: html_accept
    assert_redirected_to new_user_session_url
  end

  test "a driver cannot reach the new batch form" do
    sign_in @driver
    get new_batch_url
    assert_redirected_to root_path
  end

  test "an admin can register a batch, defaulted to active status" do
    sign_in @admin

    assert_difference "Batch.count", 1 do
      post batches_url, params: { batch: { lot_number: "LOT-2026-0001", name: "Insulin glargine", vehicle_id: @vehicle.id } }
    end

    batch = Batch.last
    assert_equal @organization, batch.organization
    assert_equal @vehicle, batch.vehicle
    assert_equal "active", batch.status
    assert_redirected_to batch_custody_logs_path(batch)
  end

  test "a dispatcher can also register a batch" do
    sign_in @dispatcher

    assert_difference "Batch.count", 1 do
      post batches_url, params: { batch: { lot_number: "LOT-2026-0002", vehicle_id: @vehicle.id } }
    end
  end

  test "a batch can be registered with a driver assigned" do
    sign_in @admin

    post batches_url, params: { batch: { lot_number: "LOT-2026-0003", vehicle_id: @vehicle.id, driver_id: @driver.id } }
    assert_equal @driver, Batch.last.driver
  end

  test "a blank vehicle is rejected with a readable error, not a raw DB error" do
    sign_in @admin

    assert_no_difference "Batch.count" do
      post batches_url, params: { batch: { lot_number: "LOT-2026-0004" } }
    end
    assert_response :unprocessable_content
  end

  test "a vehicle_id belonging to another organization is silently ignored, not assigned" do
    other_org = Organization.create!(name: "Other Pharma")
    other_vehicle = Vehicle.create!(name: "Their Truck", organization: other_org)
    sign_in @admin

    assert_no_difference "Batch.count" do
      post batches_url, params: { batch: { lot_number: "LOT-2026-0005", vehicle_id: other_vehicle.id } }
    end
    assert_response :unprocessable_content
  end

  test "a driver_id belonging to another organization is silently dropped, not assigned" do
    other_org = Organization.create!(name: "Other Pharma")
    other_driver = User.create!(email: "other-driver@example.com", password: "password123!", organization: other_org, role: "driver")
    sign_in @admin

    post batches_url, params: { batch: { lot_number: "LOT-2026-0006", vehicle_id: @vehicle.id, driver_id: other_driver.id } }
    assert_nil Batch.last.driver
  end

  test "a duplicate lot_number is rejected with a readable error" do
    sign_in @admin

    assert_no_difference "Batch.count" do
      post batches_url, params: { batch: { lot_number: "LOT-1", vehicle_id: @vehicle.id } }
    end
    assert_response :unprocessable_content
    assert_match "has already been taken", response.body
  end

  test "an admin can edit and update their own organization's batch" do
    sign_in @admin
    other_vehicle = Vehicle.create!(name: "Truck 2", organization: @organization)

    patch batch_url(@batch), params: { batch: { name: "Updated product", vehicle_id: other_vehicle.id, driver_id: @driver.id } }
    assert_redirected_to batch_custody_logs_path(@batch)
    @batch.reload
    assert_equal "Updated product", @batch.name
    assert_equal other_vehicle, @batch.vehicle
    assert_equal @driver, @batch.driver
  end

  test "a driver cannot update a batch" do
    sign_in @driver

    patch batch_url(@batch), params: { batch: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_nil @batch.reload.name
  end

  test "a user cannot edit another organization's batch" do
    other_org = Organization.create!(name: "Other Pharma")
    other_vehicle = Vehicle.create!(name: "Their Truck", organization: other_org)
    other_batch = Batch.create!(lot_number: "LOT-THEIRS", vehicle: other_vehicle, organization: other_org)
    sign_in @admin

    get edit_batch_url(other_batch)
    assert_response :not_found
  end

  private

  def html_accept
    { "Accept" => "text/html" }
  end
end
