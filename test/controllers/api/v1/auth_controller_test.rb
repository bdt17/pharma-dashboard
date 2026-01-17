require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get test_login" do
    get api_v1_auth_test_login_url
    assert_response :success
  end
end
