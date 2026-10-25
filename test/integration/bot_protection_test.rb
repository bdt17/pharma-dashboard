require "test_helper"

# BotProtection is off by default in the test suite (see the concern); these
# tests turn it on and drive the real rendered forms, so the honeypot and
# timestamp field names are exercised end to end, not just assumed.
class BotProtectionTest < ActionDispatch::IntegrationTest
  CALL_REQUEST = { name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy", topic: "general", message: "Call me" }.freeze

  setup { BotProtection.enabled = true }
  teardown { BotProtection.enabled = false }

  # Pull the signed timestamp out of a freshly rendered form.
  def form_token_from(path)
    get path
    css_select("input[name='#{BotProtection::TIMESTAMP_FIELD}']").first["value"]
  end

  def after_fill_time(&block)
    travel(BotProtection::MIN_FILL_TIME + 1.second, &block)
  end

  test "every protected form renders the honeypot and timestamp fields" do
    [ request_a_call_path, dscsa_assessment_path, new_user_registration_path ].each do |path|
      get path
      assert_select "input[name=?][tabindex='-1']", BotProtection::HONEYPOT_FIELD.to_s
      assert_select "input[type=hidden][name=?]", BotProtection::TIMESTAMP_FIELD.to_s
    end
  end

  test "a human-paced call request with an empty honeypot is saved" do
    token = form_token_from(request_a_call_path)

    after_fill_time do
      assert_difference -> { CallRequest.count }, 1 do
        post request_a_call_path, params: { call_request: CALL_REQUEST, BotProtection::TIMESTAMP_FIELD => token, BotProtection::HONEYPOT_FIELD => "" }
      end
    end
    assert_redirected_to call_request_thanks_path
  end

  test "a filled honeypot looks like success but saves nothing and sends no email" do
    token = form_token_from(request_a_call_path)

    after_fill_time do
      assert_no_difference -> { CallRequest.count } do
        assert_no_enqueued_emails do
          post request_a_call_path, params: { call_request: CALL_REQUEST, BotProtection::TIMESTAMP_FIELD => token, BotProtection::HONEYPOT_FIELD => "http://spam.example" }
        end
      end
    end
    assert_redirected_to call_request_thanks_path
    assert_equal [ "call_requests", "honeypot" ], BotBlock.last.slice(:form, :reason).values
  end

  test "a submission faster than a person could type is re-shown, not saved" do
    token = form_token_from(request_a_call_path)

    assert_no_difference -> { CallRequest.count } do
      post request_a_call_path, params: { call_request: CALL_REQUEST, BotProtection::TIMESTAMP_FIELD => token }
    end
    assert_response :unprocessable_content
    assert_select "input[name=?][value=?]", "call_request[email]", "dana@example.com"
    assert_select "input[name=?]", BotProtection::TIMESTAMP_FIELD.to_s
  end

  test "a missing, forged, or expired timestamp is rejected" do
    expired = BotProtection.form_token(2.days.ago)
    [ nil, "forged", expired ].each do |token|
      assert_no_difference -> { CallRequest.count } do
        post request_a_call_path, params: { call_request: CALL_REQUEST, BotProtection::TIMESTAMP_FIELD => token }.compact
      end
      assert_response :unprocessable_content
    end
  end

  test "the DSCSA assessment is protected" do
    answers = DscsaAssessment::ALL_KEYS.index_with { "yes" }

    assert_no_difference -> { DscsaAssessment.count } do
      post dscsa_assessment_path, params: answers.merge(BotProtection::HONEYPOT_FIELD => "x", BotProtection::TIMESTAMP_FIELD => form_token_from(dscsa_assessment_path))
    end
    assert_redirected_to dscsa_assessment_path

    token = form_token_from(dscsa_assessment_path)
    after_fill_time do
      assert_difference -> { DscsaAssessment.count }, 1 do
        post dscsa_assessment_path, params: answers.merge(BotProtection::TIMESTAMP_FIELD => token)
      end
    end
  end

  test "signup is protected and a bot gets the normal check-your-email response" do
    user_params = { organization_name: "Bot Org", email: "b.o.t.1@gmail.com", password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
    token = form_token_from(new_user_registration_path)

    after_fill_time do
      assert_no_difference -> { User.count } do
        post user_registration_path, params: { user: user_params, BotProtection::TIMESTAMP_FIELD => token, BotProtection::HONEYPOT_FIELD => "x" }
      end
      assert_response :redirect
      assert_match "confirm", flash[:notice].to_s

      assert_difference -> { User.count }, 1 do
        post user_registration_path, params: { user: user_params.merge(email: "real@example.com"), BotProtection::TIMESTAMP_FIELD => token }
      end
    end
  end
end
