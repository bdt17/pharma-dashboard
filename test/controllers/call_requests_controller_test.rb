require "test_helper"

class CallRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  def with_env(overrides)
    original = ENV.to_h
    overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    ENV.replace(original)
  end

  test "the thanks page fires the Google Ads call conversion only when configured" do
    get call_request_thanks_url
    assert_response :success
    assert_no_match "gtag('event', 'conversion'", response.body

    with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-123456789", "GOOGLE_ADS_LABEL_CALL" => "callLbl1") do
      get call_request_thanks_url
      assert_match "send_to: \"AW-123456789/callLbl1\"", response.body
    end
  end

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

  test "the compliance officer waitlist topic renders its own copy and submit label" do
    get request_a_call_url(topic: "compliance_officer_waitlist")
    assert_response :success
    assert_select "h1", text: "Get on the list."
    assert_match "Every retainer slot is taken", response.body
    assert_select "button[type=submit]", text: "Join the waitlist"
  end

  test "a compliance officer waitlist signup is stored and emailed like any other lead" do
    assert_enqueued_emails 1 do
      assert_difference "CallRequest.count", 1 do
        post request_a_call_url, params: { call_request: {
          name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy",
          topic: "compliance_officer_waitlist", message: "Please add us"
        } }
      end
    end
    assert_equal "compliance_officer_waitlist", CallRequest.last.topic
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

  test "utm attribution from an earlier landing page hit carries to the call request" do
    get dscsa_2026_url(utm_source: "google", utm_campaign: "dscsa-nov")
    post request_a_call_url, params: { call_request: {
      name: "Dana Rx", email: "dana@example.com", topic: "general"
    } }

    call_request = CallRequest.last
    assert_equal "google", call_request.utm_source
    assert_equal "dscsa-nov", call_request.utm_campaign
  end
end
