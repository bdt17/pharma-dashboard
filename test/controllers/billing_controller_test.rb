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

  test "shows the organization's own referral code and verification link" do
    sign_in @user
    get billing_url

    assert_response :success
    assert_match @organization.referral_code, response.body
    assert_match verification_url(@organization.verification_token), response.body
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
    plans = [ { id: "price_123", product_name: "Starter", amount: 99.0, currency: "usd", interval: "month", tier: "starter" } ]

    sign_in @user
    StripeBilling.stub :available_plans, plans do
      get billing_url
    end

    assert_response :success
    assert_match "Starter", response.body
    assert_match "$99.00", response.body
  end

  test "annual is the primary, pre-selected Subscribe button; monthly is secondary" do
    plans = [
      { id: "price_m", product_name: "Starter", amount: 129.0, currency: "usd", interval: "month", tier: "starter" },
      { id: "price_y", product_name: "Starter", amount: 1290.0, currency: "usd", interval: "year", tier: "starter" }
    ]

    sign_in @user
    StripeBilling.stub :available_plans, plans do
      get billing_url
    end

    assert_response :success
    assert_match "2 months free", response.body
    assert_match "or pay monthly", response.body

    doc = Nokogiri::HTML::Document.parse(response.body)
    annual_form = doc.at_css("form[action='#{billing_checkout_path(price_id: 'price_y')}']")
    monthly_form = doc.at_css("form[action='#{billing_checkout_path(price_id: 'price_m')}']")
    assert_match "btn-primary", annual_form.at_css("button")["class"]
    assert_match "btn-secondary", monthly_form.at_css("button")["class"]
    # Annual's row renders before monthly's in the response body.
    assert_operator response.body.index("price_y"), :<, response.body.index("price_m")
  end

  test "an admin on a capped plan can toggle overage billing" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    sign_in @user

    patch billing_overage_url(enabled: true)
    assert @organization.reload.overage_billing_enabled?
    assert_redirected_to billing_path

    patch billing_overage_url(enabled: false)
    assert_not @organization.reload.overage_billing_enabled?
  end

  test "a non-admin cannot toggle overage billing" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    member = User.create!(email: "m@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    sign_in member

    patch billing_overage_url(enabled: true)
    assert_not @organization.reload.overage_billing_enabled?
    assert_redirected_to billing_path
  end

  test "the overage toggle shows on a capped plan and not on an unlimited one" do
    sub = Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    sign_in @user
    StripeBilling.stub :available_plans, [] do
      get billing_url
    end
    assert_match "Overage billing", response.body

    sub.update!(tier: "compliance")
    StripeBilling.stub :available_plans, [] do
      get billing_url
    end
    assert_no_match "Overage billing", response.body
  end

  test "the billing page summarizes this month's overage charges" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "starter")
    @organization.update!(stripe_customer_id: "cus_1")
    vehicle = Vehicle.create!(name: "T", organization: @organization)
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: vehicle, organization: @organization)
    2.times do |n|
      report = ComplianceReport.create_next_version!(batch: batch, generated_by: @user, content_hash: SecureRandom.hex(32), pdf_data: "%PDF-x")
      PacketOverage.create!(organization: @organization, compliance_report: report, stripe_invoice_item_id: "ii_#{n}", amount_cents: 14_900)
    end
    sign_in @user

    StripeBilling.stub :available_plans, [] do
      get billing_url
    end
    assert_match "2 extra packets", response.body
    assert_match "$298.00", response.body
  end

  test "overage charges accrued before a mid-month upgrade still show, even off a capped plan" do
    # Was on Starter (capped), racked up an overage, then upgraded to
    # Compliance (unlimited) -- the charge is still real and still owed,
    # so it must not disappear just because @overage_eligible is now false.
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "compliance")
    @organization.update!(stripe_customer_id: "cus_1")
    vehicle = Vehicle.create!(name: "T", organization: @organization)
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: vehicle, organization: @organization)
    report = ComplianceReport.create_next_version!(batch: batch, generated_by: @user, content_hash: SecureRandom.hex(32), pdf_data: "%PDF-x")
    PacketOverage.create!(organization: @organization, compliance_report: report, stripe_invoice_item_id: "ii_1", amount_cents: 14_900)
    sign_in @user

    StripeBilling.stub :available_plans, [] do
      get billing_url
    end
    assert_match "Overage charges this month", response.body
    assert_match "1 extra packet", response.body
    assert_match "$149.00", response.body
    refute_match "Turn off overage billing", response.body # not eligible -- no toggle, just the charge
    refute_match "Turn on overage billing", response.body
  end

  test "no stray overage card when there's nothing accrued and the plan isn't overage-eligible" do
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_s", tier: "compliance")
    sign_in @user

    StripeBilling.stub :available_plans, [] do
      get billing_url
    end
    refute_match "Overage charges this month", response.body
    refute_match "Overage billing", response.body
  end

  test "the Enterprise tier is not a self-serve Subscribe button, just a contact link" do
    plans = [
      { id: "price_s", product_name: "Starter", amount: 99.0, currency: "usd", interval: "month", tier: "starter" },
      { id: "price_e", product_name: "Enterprise", amount: 1499.0, currency: "usd", interval: "month", tier: "enterprise" }
    ]

    sign_in @user
    StripeBilling.stub :available_plans, plans do
      get billing_url
    end

    assert_response :success
    assert_select "form[action=?]", billing_checkout_path(price_id: "price_s")
    assert_select "form[action=?]", billing_checkout_path(price_id: "price_e"), count: 0
    assert_select "a[href=?]", request_a_call_path(topic: "enterprise")
  end

  # Regression test for a real production incident (2026-09-03): a
  # leftover Stripe Price from an abandoned experiment, untagged and
  # unrelated to any current SubscriptionPlan tier, rendered as a live
  # Subscribe button on the actual Billing page once the account had more
  # than one stray active Price lying around. @plans must allow-list by
  # recognized self-serve tier, not just render whatever Stripe returns.
  test "an untagged or unrecognized Stripe price never renders as a Subscribe button" do
    plans = [
      { id: "price_s", product_name: "Starter", amount: 129.0, currency: "usd", interval: "month", tier: "starter" },
      { id: "price_orphan", product_name: "Pharma Transport Pro", amount: 200.0, currency: "usd", interval: "month", tier: nil }
    ]

    sign_in @user
    StripeBilling.stub :available_plans, plans do
      get billing_url
    end

    assert_response :success
    assert_select "form[action=?]", billing_checkout_path(price_id: "price_s")
    assert_select "form[action=?]", billing_checkout_path(price_id: "price_orphan"), count: 0
    assert_no_match "Pharma Transport Pro", response.body
  end

  test "shows the founding-customer offer banner before the cutoff, not after" do
    plans = [ { id: "price_123", product_name: "Starter", amount: 200.0, currency: "usd", interval: "month", tier: "starter" } ]
    sign_in @user

    StripeBilling.stub :available_plans, plans do
      travel_to StripeBilling.founding_offer_cutoff - 1.day do
        get billing_url
      end
    end
    assert_match "Founding customer offer", response.body

    StripeBilling.stub :available_plans, plans do
      travel_to StripeBilling.founding_offer_cutoff + 1.day do
        get billing_url
      end
    end
    assert_no_match "Founding customer offer", response.body
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
