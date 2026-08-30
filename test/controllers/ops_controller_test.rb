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
end
