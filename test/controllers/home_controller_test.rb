require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home page renders successfully" do
    get root_url
    assert_response :success
  end

  test "health endpoint responds successfully" do
    get health_url
    assert_response :success
  end
end
