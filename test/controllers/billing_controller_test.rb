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

  test "lists available plans from Stripe when there's no active subscription" do
    plans = [ { id: "price_123", product_name: "Starter", amount: 99.0, currency: "usd", interval: "month" } ]

    sign_in @user
    StripeBilling.stub :available_plans, plans do
      get billing_url
    end

    assert_response :success
    assert_match "Starter", response.body
    assert_match "$99.00", response.body
  end

  test "does not fetch plans once there's an active subscription" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active")

    sign_in @user
    StripeBilling.stub :available_plans, ->(*) { raise "should not be called" } do
      get billing_url
    end

    assert_response :success
  end

  test "lists available addons and any unused credits when there's no active subscription" do
    addons = [ { id: "price_addon", product_name: "Extra Compliance Packet", amount: 149.0, currency: "usd" } ]
    ReportCredit.grant!(organization: @organization, stripe_checkout_session_id: "cs_1")

    sign_in @user
    StripeBilling.stub :available_addons, addons do
      get billing_url
    end

    assert_response :success
    assert_match "Extra Compliance Packet", response.body
    assert_match "1 unused credit", response.body
  end

  test "does not fetch addons once there's an active subscription" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active")

    sign_in @user
    StripeBilling.stub :available_addons, ->(*) { raise "should not be called" } do
      get billing_url
    end

    assert_response :success
  end

  test "checkout redirects to the real Stripe URL for an admin" do
    sign_in @user

    StripeBilling.stub :start_checkout!, "https://checkout.stripe.com/fake-session" do
      post billing_checkout_url, params: { price_id: "price_123" }
    end

    assert_redirected_to "https://checkout.stripe.com/fake-session"
  end

  test "checkout is forbidden for a non-admin" do
    driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    sign_in driver

    StripeBilling.stub :start_checkout!, ->(*) { raise "should not be called" } do
      post billing_checkout_url, params: { price_id: "price_123" }
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "Only an organization admin", response.body
  end

  test "checkout handles Stripe not being configured without crashing" do
    sign_in @user

    StripeBilling.stub :start_checkout!, ->(*) { raise StripeBilling::NotConfigured } do
      post billing_checkout_url, params: { price_id: "price_123" }
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "isn't configured yet", response.body
  end

  test "addon_checkout redirects to the real Stripe URL for an admin" do
    sign_in @user

    StripeBilling.stub :start_addon_checkout!, "https://checkout.stripe.com/fake-addon-session" do
      post billing_addon_checkout_url, params: { price_id: "price_addon" }
    end

    assert_redirected_to "https://checkout.stripe.com/fake-addon-session"
  end

  test "addon_checkout is forbidden for a non-admin" do
    driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    sign_in driver

    StripeBilling.stub :start_addon_checkout!, ->(*) { raise "should not be called" } do
      post billing_addon_checkout_url, params: { price_id: "price_addon" }
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "Only an organization admin", response.body
  end

  test "addon_checkout handles Stripe not being configured without crashing" do
    sign_in @user

    StripeBilling.stub :start_addon_checkout!, ->(*) { raise StripeBilling::NotConfigured } do
      post billing_addon_checkout_url, params: { price_id: "price_addon" }
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "isn't configured yet", response.body
  end

  test "portal redirects to the real Stripe Billing Portal URL, even for a non-admin" do
    @organization.update!(stripe_customer_id: "cus_123")
    driver = User.create!(email: "driver@example.com", password: "password123!", organization: @organization, role: "driver")
    sign_in driver

    StripeBilling.stub :billing_portal_url, "https://billing.stripe.com/session/fake" do
      post billing_portal_url
    end

    assert_redirected_to "https://billing.stripe.com/session/fake"
  end

  test "portal redirects back to billing with a message when there's no Stripe customer yet" do
    sign_in @user

    StripeBilling.stub :billing_portal_url, ->(*) { raise "should not be called" } do
      post billing_portal_url
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "subscribe first", response.body
  end

  test "portal handles Stripe not being configured without crashing" do
    @organization.update!(stripe_customer_id: "cus_123")
    sign_in @user

    StripeBilling.stub :billing_portal_url, ->(*) { raise StripeBilling::NotConfigured } do
      post billing_portal_url
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "isn't configured yet", response.body
  end

  test "portal handles a Stripe error (e.g. no portal configuration yet) without crashing" do
    @organization.update!(stripe_customer_id: "cus_123")
    sign_in @user

    StripeBilling.stub :billing_portal_url, ->(*) { raise Stripe::InvalidRequestError.new("No configuration provided", nil) } do
      post billing_portal_url
    end

    assert_redirected_to billing_url
    follow_redirect!
    assert_match "open the billing portal", response.body
  end
end
