require "test_helper"

class ComplianceReportQuotaTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  def generate_report!
    ComplianceReport.create_next_version!(
      batch: @batch, generated_by: @admin,
      content_hash: SecureRandom.hex(32), pdf_data: "%PDF-fake"
    )
  end

  test "an organization with no subscription gets the free monthly limit" do
    quota = ComplianceReportQuota.new(@organization)
    assert_not quota.unlimited?
    assert_equal ComplianceReportQuota::FREE_MONTHLY_LIMIT, quota.remaining
    assert_not quota.exceeded?
  end

  test "remaining counts down as reports are generated this month" do
    generate_report!
    quota = ComplianceReportQuota.new(@organization)
    assert_equal ComplianceReportQuota::FREE_MONTHLY_LIMIT - 1, quota.remaining
  end

  test "is exceeded once the free limit is used up" do
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { generate_report! }

    quota = ComplianceReportQuota.new(@organization)
    assert quota.exceeded?
    assert_equal 0, quota.remaining
  end

  test "reports from a previous month don't count against this month's quota" do
    generate_report!
    ComplianceReport.update_all(created_at: 2.months.ago)

    quota = ComplianceReportQuota.new(@organization)
    assert_not quota.exceeded?
    assert_equal ComplianceReportQuota::FREE_MONTHLY_LIMIT, quota.remaining
  end

  test "an active subscription makes the quota unlimited, regardless of usage" do
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { generate_report! }
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_123")

    quota = ComplianceReportQuota.new(@organization)
    assert quota.unlimited?
    assert_nil quota.remaining
    assert_not quota.exceeded?
  end

  test "a trialing subscription is also unlimited" do
    Subscription.create!(organization: @organization, status: "trialing", stripe_subscription_id: "sub_456")

    assert ComplianceReportQuota.new(@organization).unlimited?
  end

  test "a canceled subscription does not grant unlimited generation" do
    Subscription.create!(organization: @organization, status: "canceled", stripe_subscription_id: "sub_789")

    assert_not ComplianceReportQuota.new(@organization).unlimited?
  end

  test "only the most recent subscription matters when an org has more than one" do
    Subscription.create!(organization: @organization, status: "canceled", stripe_subscription_id: "sub_old", created_at: 1.year.ago)
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_new")

    assert ComplianceReportQuota.new(@organization).unlimited?
  end

  test "a purchased credit is not touched while free monthly quota still has room" do
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    quota = ComplianceReportQuota.new(@organization)
    assert_not quota.exceeded?
    assert_nil quota.credit_to_consume
  end

  test "a purchased credit covers generation once the free monthly quota is used up" do
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { generate_report! }
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    quota = ComplianceReportQuota.new(@organization)
    assert_not quota.exceeded?
    assert_equal credit, quota.credit_to_consume
  end

  test "is still exceeded once the free quota is used up and there's no credit" do
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { generate_report! }

    quota = ComplianceReportQuota.new(@organization)
    assert quota.exceeded?
    assert_nil quota.credit_to_consume
  end

  test "an already-consumed credit does not count as available" do
    ComplianceReportQuota::FREE_MONTHLY_LIMIT.times { generate_report! }
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1").consume!

    quota = ComplianceReportQuota.new(@organization)
    assert quota.exceeded?
    assert_nil quota.credit_to_consume
  end

  test "an unlimited subscription never needs a credit, even if one is available" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_123")
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    assert_nil ComplianceReportQuota.new(@organization).credit_to_consume
  end

  # --- tiered plans ---

  test "the starter tier caps generation at its monthly packet allowance" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    quota = ComplianceReportQuota.new(@organization)

    assert_not quota.unlimited?
    assert_equal SubscriptionPlan::STARTER.packet_allowance, quota.monthly_allowance
    assert_equal SubscriptionPlan::STARTER.packet_allowance, quota.remaining

    SubscriptionPlan::STARTER.packet_allowance.times { generate_report! }
    assert ComplianceReportQuota.new(@organization).exceeded?
  end

  test "the pro tier has a higher allowance than starter" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_p", tier: "pro")
    assert_equal 60, ComplianceReportQuota.new(@organization).monthly_allowance
  end

  test "the compliance tier is unlimited" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_c", tier: "compliance")
    quota = ComplianceReportQuota.new(@organization)

    assert quota.unlimited?
    assert_nil quota.remaining
  end

  test "a subscription with no tier stays unlimited (pre-tier behaviour)" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_legacy", tier: nil)
    assert ComplianceReportQuota.new(@organization).unlimited?
  end

  test "a purchased credit still covers a starter over-limit generation" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    SubscriptionPlan::STARTER.packet_allowance.times { generate_report! }
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    quota = ComplianceReportQuota.new(@organization)
    assert_not quota.exceeded?
    assert_equal credit, quota.credit_to_consume
  end
end
