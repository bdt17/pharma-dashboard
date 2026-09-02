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
end
