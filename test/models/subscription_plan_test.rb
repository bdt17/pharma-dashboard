require "test_helper"

class SubscriptionPlanTest < ActiveSupport::TestCase
  test "there are three tiers in ascending price order" do
    assert_equal %w[starter pro compliance], SubscriptionPlan.tiers
    amounts = SubscriptionPlan::ALL.map(&:monthly_cents)
    assert_equal amounts.sort, amounts
  end

  test "find returns the plan for a tier and nil for anything else" do
    assert_equal "Pro", SubscriptionPlan.find("pro").name
    assert_nil SubscriptionPlan.find("enterprise")
    assert_nil SubscriptionPlan.find(nil)
  end

  test "only the compliance tier has an unlimited packet allowance" do
    assert_equal [ SubscriptionPlan::COMPLIANCE ], SubscriptionPlan::ALL.select(&:unlimited_packets?)
    assert_equal 15, SubscriptionPlan::STARTER.packet_allowance
    assert_equal 60, SubscriptionPlan::PRO.packet_allowance
  end

  test "monthly_dollars is the whole-dollar amount" do
    assert_equal 99, SubscriptionPlan::STARTER.monthly_dollars
  end
end
