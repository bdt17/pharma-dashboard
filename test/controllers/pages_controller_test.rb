require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "pricing page is public and renders" do
    get pricing_url
    assert_response :success
    assert_select "h1", "Simple, transparent pricing."
  end

  test "pricing page offers Enterprise as a contact-sales tier" do
    get pricing_url
    assert_select "a[href=?]", request_a_call_path(topic: "enterprise"), text: /Talk to us/
    assert_select ".btn", text: "Start free trial", count: SubscriptionPlan.self_serve.size
  end

  test "about page is public and renders" do
    get about_url
    assert_response :success
    assert_select "h2", text: "Who’s behind this"
  end

  test "security page is public and renders" do
    get security_url
    assert_response :success
    assert_select "h1", text: /survive an audit/
  end

  test "the home page links to the security page" do
    get root_url
    assert_select "a[href=?]", security_path
  end

  test "compliance officer page is public and renders" do
    get compliance_officer_url
    assert_response :success
    assert_select "h1", text: /can.t hire one/
  end

  test "the home page teases the compliance officer service" do
    get root_url
    assert_select "a[href=?]", compliance_officer_path
  end

  test "the DSCSA 2026 landing page is public, renders, and points at the free check" do
    get dscsa_2026_url
    assert_response :success
    assert_select "h1", text: /DSCSA deadline/
    assert_select "a[href=?]", dscsa_assessment_path, text: /readiness check/
  end

  test "the DSCSA 2026 landing page shows the live Starter price, not a hardcoded one" do
    plans = [ { id: "price_s", product_name: "Starter", amount: 250.0, currency: "usd", interval: "month", tier: "starter" } ]

    StripeBilling.stub :available_plans, plans do
      get dscsa_2026_url
    end

    assert_match "$250/month", response.body
  end

  test "the DSCSA 2026 landing page falls back to the plan constant when Stripe has nothing" do
    StripeBilling.stub :available_plans, [] do
      get dscsa_2026_url
    end

    assert_match "$#{SubscriptionPlan::STARTER.monthly_dollars}/month", response.body
  end
end
