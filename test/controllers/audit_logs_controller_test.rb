require "test_helper"

class AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
  end

  test "requires authentication" do
    get audit_logs_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "is open to any org member, not just admins" do
    sign_in @driver
    get audit_logs_url
    assert_response :success
  end

  test "shows this organization's audit log, not another organization's" do
    other_org = Organization.create!(name: "Other Pharma")
    other_admin = User.create!(email: "other-admin@example.com", password: "password123!", organization: other_org, role: "admin")
    AuditLog.record!(event: "our_event", user: @admin)
    AuditLog.record!(event: "their_event", user: other_admin)

    sign_in @admin
    get audit_logs_url

    assert_response :success
    assert_match "our_event", response.body
    assert_no_match "their_event", response.body
  end

  test "the CSV export returns a real CSV with only this organization's rows" do
    other_org = Organization.create!(name: "Other Pharma")
    other_admin = User.create!(email: "other-admin@example.com", password: "password123!", organization: other_org, role: "admin")
    AuditLog.record!(event: "our_event", user: @admin)
    AuditLog.record!(event: "their_event", user: other_admin)

    sign_in @admin
    get audit_logs_csv_url

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment.*\.csv/, response.headers["Content-Disposition"])

    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "our_event" ], rows.map { |r| r["Event"] }
  end

  test "an empty audit log shows a real empty state, not an error" do
    sign_in @admin
    get audit_logs_url

    assert_response :success
    assert_match "No audited events yet", response.body
  end
end
