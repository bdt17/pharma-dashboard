require "test_helper"

class ReportCreditTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  test "grant! creates a credit for a new checkout session" do
    assert_difference "ReportCredit.count", 1 do
      ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_123")
    end

    credit = ReportCredit.last
    assert_equal @organization, credit.organization
    assert_nil credit.consumed_at
  end

  test "grant! is idempotent for the same checkout session id" do
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_123")

    assert_no_difference "ReportCredit.count" do
      ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_123")
    end
  end

  test "available scope excludes consumed credits" do
    unconsumed = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")
    consumed = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_2")
    consumed.consume!

    assert_equal [ unconsumed ], @organization.report_credits.available
  end

  test "consume! marks the credit spent" do
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")
    credit.consume!

    assert_not_nil credit.reload.consumed_at
  end

  test "consume! is a no-op the second time, not a second spend" do
    credit = ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")
    credit.consume!
    first_consumed_at = credit.reload.consumed_at

    travel 1.hour do
      credit.consume!
    end

    assert_equal first_consumed_at, credit.reload.consumed_at
  end
end
