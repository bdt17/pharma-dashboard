require "test_helper"

class CallRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "new renders with the topic from the query string" do
    get request_a_call_url(topic: "compliance_officer")
    assert_response :success
    assert_select "input[type=hidden][name=?][value=?]", "call_request[topic]", "compliance_officer"
  end

  test "an unknown topic falls back to general" do
    get request_a_call_url(topic: "../etc/passwd")
    assert_response :success
    assert_select "input[type=hidden][name=?][value=?]", "call_request[topic]", "general"
  end

  test "create stores the lead, emails the team, and redirects to thanks" do
    assert_enqueued_emails 1 do
      assert_difference "CallRequest.count", 1 do
        post request_a_call_url, params: { call_request: {
          name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy",
          topic: "compliance_officer", message: "Interested"
        } }
      end
    end
    assert_redirected_to call_request_thanks_path
    assert_equal "compliance_officer", CallRequest.last.topic
  end

  test "create re-renders on validation failure" do
    assert_no_difference "CallRequest.count" do
      post request_a_call_url, params: { call_request: { name: "", email: "bad", topic: "general" } }
    end
    assert_response :unprocessable_content
  end

  test "create coerces a spoofed topic to general" do
    post request_a_call_url, params: { call_request: {
      name: "X", email: "x@example.com", topic: "admin"
    } }
    assert_redirected_to call_request_thanks_path
    assert_equal "general", CallRequest.last.topic
  end
end
