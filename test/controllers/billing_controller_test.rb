require "test_helper"

class BillingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  test "requires authentication" do
    get billing_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows 'no subscription' honestly when there isn't one" do
    sign_in @user
    get billing_url

    assert_response :success
    assert_match "No subscription on file", response.body
  end

  test "shows the organization's real subscription status" do
    Subscription.sync_from_stripe!(
      organization: @organization,
      stripe_subscription_id: "sub_123",
      status: "active",
      plan_amount: 99.0
    )

    sign_in @user
    get billing_url

    assert_response :success
    assert_match "Active", response.body
    assert_match "$99.00", response.body
  end
end
