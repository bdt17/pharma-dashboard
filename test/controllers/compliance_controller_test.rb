require "test_helper"

class ComplianceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get compliance_index_url
    assert_response :success
  end

  test "should get logs" do
    get compliance_logs_url
    assert_response :success
  end

  test "should get signatures" do
    get compliance_signatures_url
    assert_response :success
  end
end
