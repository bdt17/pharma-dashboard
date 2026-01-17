require "test_helper"

class RevenueControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get revenue_index_url
    assert_response :success
  end
end
