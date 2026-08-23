require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "terms page is public and renders" do
    get terms_url
    assert_response :success
    assert_select "h1", "Terms of Service"
  end

  test "privacy page is public and renders" do
    get privacy_url
    assert_response :success
    assert_select "h1", "Privacy Policy"
  end

  test "footer links to both pages" do
    get root_url
    assert_select "a[href=?]", terms_path
    assert_select "a[href=?]", privacy_path
  end
end
