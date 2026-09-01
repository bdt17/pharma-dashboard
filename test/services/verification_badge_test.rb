require "test_helper"

class VerificationBadgeTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  test "well-formed SVG with the verified label and teal fill for a subscribed org" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_1")

    svg = VerificationBadge.new(@organization).svg

    assert svg.start_with?("<svg")
    assert svg.strip.end_with?("</svg>")
    assert_includes svg, "DSCSA verified"
    assert_includes svg, VerificationBadge::VERIFIED_BG
    assert_includes svg, 'xmlns="http://www.w3.org/2000/svg"'
  end

  test "shows the not-verified label and grey fill without an active subscription" do
    svg = VerificationBadge.new(@organization).svg

    assert_includes svg, "not verified"
    assert_includes svg, VerificationBadge::UNVERIFIED_BG
    assert_not_includes svg, "DSCSA verified"
  end

  test "trialing counts as verified" do
    Subscription.create!(organization: @organization, status: "trialing", stripe_subscription_id: "sub_1")
    assert_includes VerificationBadge.new(@organization).svg, "DSCSA verified"
  end
end
