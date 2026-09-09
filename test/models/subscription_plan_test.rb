require "test_helper"

class SubscriptionPlanTest < ActiveSupport::TestCase
  test "tiers are listed in ascending price order" do
    assert_equal %w[starter pro compliance enterprise], SubscriptionPlan.tiers
    amounts = SubscriptionPlan::ALL.map(&:monthly_cents)
    assert_equal amounts.sort, amounts
  end

  test "find returns the plan for a tier and nil for anything else" do
    assert_equal "Pro", SubscriptionPlan.find("pro").name
    assert_equal "Enterprise", SubscriptionPlan.find("enterprise").name
    assert_nil SubscriptionPlan.find("platinum")
    assert_nil SubscriptionPlan.find(nil)
  end

  test "the compliance and enterprise tiers have an unlimited packet allowance" do
    assert_equal [ SubscriptionPlan::COMPLIANCE, SubscriptionPlan::ENTERPRISE ],
                 SubscriptionPlan::ALL.select(&:unlimited_packets?)
    assert_equal 15, SubscriptionPlan::STARTER.packet_allowance
    assert_equal 60, SubscriptionPlan::PRO.packet_allowance
  end

  test "only Enterprise is a contact-sales tier, and self_serve excludes it" do
    assert SubscriptionPlan::ENTERPRISE.contact_sales?
    assert_not SubscriptionPlan::COMPLIANCE.contact_sales?
    assert_equal %w[starter pro compliance], SubscriptionPlan.self_serve.map(&:tier)
  end

  test "monthly_dollars is the whole-dollar amount" do
    assert_equal 129, SubscriptionPlan::STARTER.monthly_dollars
    assert_equal 1_499, SubscriptionPlan::ENTERPRISE.monthly_dollars
  end

  # Regression test: the Enterprise feature list used to list "Single
  # sign-on (SAML)" as included, with no SSO code anywhere in the app --
  # a marketed-but-not-built claim on the actual pricing page. Removed
  # rather than built, since nothing self-serve backs it; SSO stays
  # something discussed on the Enterprise sales call (see billing/index
  # and call_requests/new's own copy), not a bullet implying it's ready
  # today. This just guards against the bullet quietly coming back.
  test "the enterprise feature list does not claim SSO/SAML is included" do
    SubscriptionPlan::ALL.each do |plan|
      assert_not plan.features.any? { |f| f.match?(/single sign-on|\bSSO\b|\bSAML\b/i) },
        "#{plan.name} features list an SSO/SAML claim, but no SSO is implemented anywhere in the app"
    end
  end
end
