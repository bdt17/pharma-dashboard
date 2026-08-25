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

  test "grant_batch! creates one credit per unit for a new checkout session" do
    credits = nil
    assert_difference "ReportCredit.count", 10 do
      credits = ReportCredit.grant_batch!(organization: @organization, stripe_checkout_session_id: "cs_bulk", quantity: 10)
    end

    assert_equal 10, credits.size
    assert_equal (1..10).to_a, credits.map(&:sequence)
    assert credits.all? { |c| c.organization == @organization && c.consumed_at.nil? }
  end

  test "grant_batch! is idempotent for the same checkout session id -- skips the whole batch on replay" do
    ReportCredit.grant_batch!(organization: @organization, stripe_checkout_session_id: "cs_bulk", quantity: 10)

    assert_no_difference "ReportCredit.count" do
      result = ReportCredit.grant_batch!(organization: @organization, stripe_checkout_session_id: "cs_bulk", quantity: 10)
      assert_equal [], result
    end
  end

  test "credits from a batch are each independently available and consumable" do
    ReportCredit.grant_batch!(organization: @organization, stripe_checkout_session_id: "cs_bulk", quantity: 3)

    assert_equal 3, @organization.report_credits.available.count
    @organization.report_credits.available.first.consume!
    assert_equal 2, @organization.report_credits.available.count
  end
end
