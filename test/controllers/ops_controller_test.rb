require "test_helper"

class OpsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @org = Organization.create!(name: "Acme Pharma")
    @operator = User.create!(email: "ops@example.com", password: "password123!", organization: @org, role: "admin")
    @other_admin = User.create!(email: "someone@example.com", password: "password123!", organization: @org, role: "admin")
  end

  def with_operator_emails(value)
    original = ENV["OPERATOR_EMAILS"]
    ENV["OPERATOR_EMAILS"] = value
    yield
  ensure
    original.nil? ? ENV.delete("OPERATOR_EMAILS") : ENV["OPERATOR_EMAILS"] = original
  end

  test "requires sign-in" do
    with_operator_emails("ops@example.com") do
      get ops_url, headers: { "Accept" => "text/html" }
      assert_redirected_to new_user_session_url
    end
  end

  test "404s when OPERATOR_EMAILS is unset" do
    sign_in @operator
    get ops_url
    assert_response :not_found
  end

  test "404s for a signed-in admin not on the allowlist" do
    with_operator_emails("ops@example.com") do
      sign_in @other_admin
      get ops_url
      assert_response :not_found
    end
  end

  test "renders the diagnostics for an allowlisted operator" do
    with_operator_emails("someone-else@example.com, OPS@example.com") do
      sign_in @operator
      get ops_url
      assert_response :success
      assert_select "h1", "Ops diagnostics"
      assert_select "table"
    end
  end

  test "the test-email button sends an email to the operator" do
    with_operator_emails("ops@example.com") do
      sign_in @operator
      assert_emails 1 do
        post ops_test_email_url
      end
      assert_redirected_to ops_path
      assert_equal [ "ops@example.com" ], ActionMailer::Base.deliveries.last.to
    end
  end

  test "the Check Postmark button only shows when POSTMARK_API_TOKEN is set" do
    with_operator_emails("ops@example.com") do
      sign_in @operator

      get ops_url
      assert_select "form[action=?]", ops_check_postmark_path, count: 0

      with_env("POSTMARK_API_TOKEN" => "pm-token") do
        get ops_url
        assert_select "form[action=?]", ops_check_postmark_path, count: 1
      end
    end
  end

  test "check_postmark redirects with an alert when Postmark isn't configured" do
    with_operator_emails("ops@example.com") do
      sign_in @operator
      with_env("POSTMARK_API_TOKEN" => nil) do
        post ops_check_postmark_url
      end
      assert_redirected_to ops_path
      follow_redirect!
      assert_match "not set", response.body
    end
  end

  test "check_postmark redirects with the probe result" do
    with_operator_emails("ops@example.com") do
      sign_in @operator
      ok = Ops::PostmarkCheck::Result.new(ok: true, message: "Postmark OK -- token valid for server \"X\".")
      Ops::PostmarkCheck.stub(:call, ok) do
        post ops_check_postmark_url
      end
      assert_redirected_to ops_path
      follow_redirect!
      assert_match "Postmark OK", response.body
    end
  end

  def with_env(overrides)
    original = ENV.to_h
    overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    ENV.replace(original)
  end

  # Regression test for a real bug found this session: the action used to
  # call plain deliver_now, whose internal rescue honors production's
  # raise_delivery_errors = false and swallows an SMTP failure without
  # re-raising -- the same failure mode ApplicationMailDeliveryJob was
  # built to fix, but this synchronous controller action was never
  # touched by that fix. Uses the same plain-double stubbing technique as
  # ApplicationMailDeliveryJobTest (stubbing deliver_now!/deliver_now
  # directly on the real MessageDelivery Delegator doesn't reliably land
  # on the right object).
  test "a delivery failure surfaces as a real error, not a false success" do
    with_operator_emails("ops@example.com") do
      sign_in @operator

      failing_delivery = Object.new
      def failing_delivery.deliver_now!
        raise Net::SMTPAuthenticationError, "535 authentication failed"
      end

      OpsMailer.stub :test_message, failing_delivery do
        post ops_test_email_url
      end

      assert_redirected_to ops_path
      follow_redirect!
      assert_match "Test email failed", response.body
      assert_match "SMTPAuthenticationError", response.body
    end
  end

  test "the lead inbox lists unhandled call requests and marks one handled" do
    lead = CallRequest.create!(name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy", topic: "general", message: "Call me")
    CallRequest.create!(name: "Old Lead", email: "old@example.com", topic: "general", handled_at: 1.day.ago)

    with_operator_emails("ops@example.com") do
      sign_in @operator
      get ops_url
      assert_select "#leads", text: /Dana Rx/
      assert_select "#leads", text: /Old Lead/, count: 0

      post ops_handle_call_request_url(lead)
      assert_redirected_to ops_url(anchor: "leads")
    end
    assert lead.reload.handled_at
  end

  test "lead inbox actions are operator-only" do
    lead = CallRequest.create!(name: "Dana Rx", email: "dana@example.com", topic: "general")

    with_operator_emails("ops@example.com") do
      sign_in @other_admin
      post ops_handle_call_request_url(lead)
      assert_response :not_found
      post ops_set_internal_url(@org, internal: true)
      assert_response :not_found
    end
    assert_nil lead.reload.handled_at
    assert_not @org.reload.internal?
  end

  test "marking an org internal drops it and its subscriptions out of the customer counts" do
    test_org = Organization.create!(name: "Monetize Check")
    test_org.subscriptions.create!(stripe_subscription_id: "sub_test", status: "active")

    with_operator_emails("ops@example.com") do
      sign_in @operator
      post ops_set_internal_url(test_org, internal: true)
      assert_redirected_to ops_url(anchor: "organizations")

      get ops_url
      assert_match "(+1 internal org hidden)", response.body
      assert_match "(+1 on internal orgs)", response.body

      post ops_set_internal_url(test_org, internal: false)
    end
    assert_not test_org.reload.internal?
  end

  test "blocked bot submissions are counted on the page" do
    BotBlock.record!(form: "call_requests", reason: "honeypot")
    BotBlock.record!(form: "users/registrations", reason: "too_fast")

    with_operator_emails("ops@example.com") do
      sign_in @operator
      get ops_url
    end
    assert_match "2 -- call_requests: 1, signup: 1", response.body
  end
end
