require "test_helper"

class BatchesControllerTest < ActionDispatch::IntegrationTest
  test "should get chain_of_custody" do
    get batches_chain_of_custody_url
    assert_response :success
  end
end
