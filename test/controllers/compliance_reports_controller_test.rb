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

  test "generation is blocked once the free monthly limit is reached" do
    sign_in @admin
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { post batch_compliance_reports_url(@batch) }

    assert_no_difference "ComplianceReport.count" do
      post batch_compliance_reports_url(@batch)
    end

    assert_redirected_to batch_compliance_reports_url(@batch)
    follow_redirect!
    assert_match "Monthly limit reached", response.body
  end

  test "an active subscription removes the free monthly limit" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_123")
    sign_in @admin
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { post batch_compliance_reports_url(@batch) }

    assert_difference "ComplianceReport.count", 1 do
      post batch_compliance_reports_url(@batch)
    end
  end

  test "hitting the quota does not create an audit log entry" do
    sign_in @admin
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { post batch_compliance_reports_url(@batch) }

    assert_no_difference "AuditLog.count" do
      post batch_compliance_reports_url(@batch)
    end
  end

  test "a purchased credit covers generation once the free monthly limit is used up" do
    sign_in @admin
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { post batch_compliance_reports_url(@batch) }
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    assert_difference "ComplianceReport.count", 1 do
      post batch_compliance_reports_url(@batch)
    end

    assert_not_nil credit.reload.consumed_at
  end

  test "a purchased credit is left untouched while free monthly quota still has room" do
    sign_in @admin
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    post batch_compliance_reports_url(@batch)

    assert_nil credit.reload.consumed_at
  end

  test "generation is still blocked once the free limit and any credit are both used up" do
    sign_in @admin
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { post batch_compliance_reports_url(@batch) }
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")
    post batch_compliance_reports_url(@batch) # spends the one credit

    assert_no_difference "ComplianceReport.count" do
      post batch_compliance_reports_url(@batch)
    end
  end

  # --- overage billing ---

  def fill_starter_allowance!
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    @organization.update!(stripe_customer_id: "cus_1")
    SubscriptionPlan::STARTER.packet_allowance.times do
      ComplianceReport.create_next_version!(batch: @batch, generated_by: @admin, content_hash: SecureRandom.hex(32), pdf_data: "%PDF-x")
    end
  end

  OVERAGE_ITEM = { invoice_item_id: "ii_1", amount_cents: 14_900, currency: "usd" }.freeze

  test "with overage billing on, a capped plan past its allowance generates and is invoiced" do
    fill_starter_allowance!
    @organization.update!(overage_billing_enabled: true)
    sign_in @admin

    called_with = nil
    StripeBilling.stub :add_packet_overage_item!, ->(**kw) { called_with = kw; OVERAGE_ITEM } do
      assert_difference [ "ComplianceReport.count", "PacketOverage.count" ], 1 do
        post batch_compliance_reports_url(@batch)
      end
    end

    overage = PacketOverage.last
    assert_equal ComplianceReport.last, overage.compliance_report
    assert_equal "ii_1", overage.stripe_invoice_item_id
    assert_equal @organization, called_with[:organization]
    assert_redirected_to batch_compliance_report_url(@batch, ComplianceReport.last)
    follow_redirect!
    assert_match "added to your next invoice", response.body
  end

  test "with overage billing off, a capped plan past its allowance is still blocked" do
    fill_starter_allowance!
    @organization.update!(overage_billing_enabled: false)
    sign_in @admin

    StripeBilling.stub :add_packet_overage_item!, ->(**) { flunk "must not bill when overage is off" } do
      assert_no_difference "ComplianceReport.count" do
        post batch_compliance_reports_url(@batch)
      end
    end
    assert_redirected_to batch_compliance_reports_url(@batch)
  end

  test "a Stripe failure during overage blocks the generation -- no free packet" do
    fill_starter_allowance!
    @organization.update!(overage_billing_enabled: true)
    sign_in @admin

    StripeBilling.stub :add_packet_overage_item!, ->(**) { raise StripeBilling::NotConfigured } do
      assert_no_difference [ "ComplianceReport.count", "PacketOverage.count" ] do
        post batch_compliance_reports_url(@batch)
      end
    end
    assert_redirected_to batch_compliance_reports_url(@batch)
    follow_redirect!
    assert_match "add an extra packet to your next invoice", response.body
  end

  test "a purchased credit is still spent before an overage is billed" do
    fill_starter_allowance!
    @organization.update!(overage_billing_enabled: true)
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")
    sign_in @admin

    StripeBilling.stub :add_packet_overage_item!, ->(**) { flunk "should have used the credit" } do
      assert_difference "ComplianceReport.count", 1 do
        post batch_compliance_reports_url(@batch)
      end
    end
    assert_not_nil credit.reload.consumed_at
    assert_equal 0, PacketOverage.count
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
