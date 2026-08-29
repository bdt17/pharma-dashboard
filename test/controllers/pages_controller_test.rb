require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "pricing page is public and renders" do
    get pricing_url
    assert_response :success
    assert_select "h1", "Simple, transparent pricing."
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
end
