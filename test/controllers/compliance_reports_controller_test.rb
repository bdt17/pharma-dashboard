require "test_helper"

class ComplianceReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver", driven_batches: [ @batch ])
  end

  test "index requires authentication" do
    get batch_compliance_reports_url(@batch), headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "an admin can generate a compliance packet, and it's recorded as an audit event" do
    sign_in @admin

    assert_difference [ "ComplianceReport.count", "AuditLog.count" ], 1 do
      post batch_compliance_reports_url(@batch)
    end

    report = ComplianceReport.last
    assert_equal 1, report.version
    assert_equal @admin, report.generated_by
    assert_redirected_to batch_compliance_report_url(@batch, report)

    log = AuditLog.last
    assert_equal "compliance_report_generated", log.event
    assert_equal report.version, log.data["version"]
  end

  test "a driver -- even the one assigned to this batch -- cannot generate a compliance packet" do
    sign_in @driver

    assert_no_difference "ComplianceReport.count" do
      post batch_compliance_reports_url(@batch)
    end
  end

  test "a user from a different organization cannot generate a compliance packet" do
    other_admin = User.create!(email: "other-admin@example.com", password: "password123!", organization: Organization.create!(name: "Other Org"), role: "admin")
    sign_in other_admin

    assert_no_difference "ComplianceReport.count" do
      post batch_compliance_reports_url(@batch)
    end
  end

  test "download serves the exact real PDF bytes for that version" do
    sign_in @admin
    post batch_compliance_reports_url(@batch)
    report = ComplianceReport.last

    get batch_compliance_report_download_url(@batch, report)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
    assert_equal Digest::SHA256.hexdigest(response.body), report.content_hash
  end

  test "index lists generated versions" do
    sign_in @admin
    post batch_compliance_reports_url(@batch)
    post batch_compliance_reports_url(@batch)

    get batch_compliance_reports_url(@batch)

    assert_response :success
    assert_select "a", text: "v1"
    assert_select "a", text: "v2"
  end

  test "a user from a different organization cannot view or download packets" do
    other_admin = User.create!(email: "other-admin@example.com", password: "password123!", organization: Organization.create!(name: "Other Org"), role: "admin")
    sign_in @admin
    post batch_compliance_reports_url(@batch)
    report = ComplianceReport.last
    sign_out @admin

    sign_in other_admin
    get batch_compliance_reports_url(@batch), headers: { "Accept" => "text/html" }
    assert_redirected_to root_url

    get batch_compliance_report_download_url(@batch, report), headers: { "Accept" => "text/html" }
    assert_redirected_to root_url
  end
end
