require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @webhook_secret = SecureRandom.hex(16)
    @previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = @webhook_secret

    @organization = Organization.create!(name: "Acme Pharma", stripe_customer_id: "cus_123")
  end

  teardown do
    ENV["STRIPE_WEBHOOK_SECRET"] = @previous_secret
  end

  def signed_headers_for(payload)
    timestamp = Time.current
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, @webhook_secret)
    { "Stripe-Signature" => Stripe::Webhook::Signature.generate_header(timestamp, signature) }
  end

  # Matches the real shape Stripe sends as of API version 2025-11-17.clover:
  # current_period_end lives on the subscription item, not the subscription
  # itself.
  def subscription_event_payload(status: "active", tier: nil, type: "customer.subscription.updated",
                                 id: "sub_123", amount: 9900)
    price = { unit_amount: amount }
    price[:metadata] = { tier: tier } if tier
    {
      type: type,
      data: {
        object: {
          id: id,
          customer: "cus_123",
          status: status,
          items: { data: [ { price: price, current_period_end: 1.month.from_now.to_i } ] }
        }
      }
    }.to_json
  end

  def post_event(payload)
    post stripe_webhooks_url,
      params: payload,
      headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
  end

  test "rejects a request with no signature header" do
    post stripe_webhooks_url, params: subscription_event_payload, headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
  end

  test "rejects a request signed with the wrong secret" do
    payload = subscription_event_payload
    wrong_signature = Stripe::Webhook::Signature.compute_signature(Time.current, payload, "wrong-secret")
    headers = { "Stripe-Signature" => Stripe::Webhook::Signature.generate_header(Time.current, wrong_signature) }

    post stripe_webhooks_url, params: payload, headers: headers.merge("Content-Type" => "application/json")
    assert_response :bad_request
  end

  test "accepts a correctly signed subscription.updated event and syncs the subscription" do
    payload = subscription_event_payload

    assert_difference -> { Subscription.count }, 1 do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
    subscription = Subscription.find_by(stripe_subscription_id: "sub_123")
    assert_equal @organization, subscription.organization
    assert_equal "active", subscription.status
    assert_equal 99.0, subscription.plan_amount
    assert_not_nil subscription.current_period_end
  end

  test "syncs the tier from the price metadata when present" do
    post_event subscription_event_payload(tier: "pro")
    assert_equal "pro", Subscription.find_by(stripe_subscription_id: "sub_123").tier
  end

  test "the full subscription lifecycle: created (trial) -> active -> upgrade -> canceled" do
    post_event subscription_event_payload(type: "customer.subscription.created", status: "trialing", tier: "starter", amount: 9900)
    sub = Subscription.find_by(stripe_subscription_id: "sub_123")
    assert sub.trialing?
    assert_equal "starter", sub.tier

    post_event subscription_event_payload(status: "active", tier: "starter", amount: 9900)
    assert sub.reload.active?
    assert_equal 15, ComplianceReportQuota.new(@organization).monthly_allowance

    post_event subscription_event_payload(status: "active", tier: "pro", amount: 24_900)
    assert_equal "pro", sub.reload.tier
    assert_equal 24_900 / 100.0, sub.plan_amount
    assert_equal 60, ComplianceReportQuota.new(@organization).monthly_allowance

    post_event subscription_event_payload(status: "active", tier: "compliance", amount: 49_900)
    assert ComplianceReportQuota.new(@organization).unlimited?

    payload = { type: "customer.subscription.deleted", data: { object: { id: "sub_123", customer: "cus_123" } } }.to_json
    post_event payload
    assert sub.reload.canceled?
    assert_not ComplianceReportQuota.new(@organization).unlimited?
  end

  test "a past_due status syncs through" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active", tier: "pro")
    post_event subscription_event_payload(status: "past_due", tier: "pro")
    assert Subscription.find_by(stripe_subscription_id: "sub_123").past_due?
  end

  test "a past_due event sends the payment-recovery email once" do
    User.create!(email: "admin@acme.test", password: "password123!", organization: @organization, role: "admin")
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active", tier: "pro")

    assert_enqueued_emails 1 do
      post_event subscription_event_payload(status: "past_due", tier: "pro")
    end

    assert_no_enqueued_emails do
      post_event subscription_event_payload(status: "past_due", tier: "pro")
    end
    assert_equal 1, Subscription.find_by(stripe_subscription_id: "sub_123").dunning_email_count
  end

  test "replaying the same subscription event is idempotent" do
    2.times { post_event subscription_event_payload(status: "active", tier: "pro") }
    assert_equal 1, Subscription.where(stripe_subscription_id: "sub_123").count
  end

  test "accepts a correctly signed subscription.deleted event and cancels the subscription" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_123", status: "active")

    payload = {
      type: "customer.subscription.deleted",
      data: { object: { id: "sub_123", customer: "cus_123" } }
    }.to_json

    post stripe_webhooks_url,
      params: payload,
      headers: signed_headers_for(payload).merge("Content-Type" => "application/json")

    assert_response :success
    assert_equal "canceled", Subscription.find_by(stripe_subscription_id: "sub_123").status
  end

  test "an active subscription event triggers the referral reward for a pending referral" do
    referrer = Organization.create!(name: "Referring Pharmacy")
    Referral.create!(referrer_organization: referrer, referred_organization: @organization)
    payload = subscription_event_payload(status: "active")

    Stripe::Subscription.stub :update, ->(*) { } do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
    assert_not_nil Referral.find_by(referred_organization: @organization).rewarded_at
  end

  test "a trialing (not yet active) subscription event does not trigger the referral reward" do
    referrer = Organization.create!(name: "Referring Pharmacy")
    Referral.create!(referrer_organization: referrer, referred_organization: @organization)
    payload = subscription_event_payload(status: "trialing")

    Stripe::Subscription.stub :update, ->(*) { raise "should not be called" } do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
    assert_nil Referral.find_by(referred_organization: @organization).rewarded_at
  end

  test "ignores an event for a customer with no matching organization instead of raising" do
    payload = {
      type: "customer.subscription.updated",
      data: { object: { id: "sub_999", customer: "cus_unknown", status: "active", items: { data: [] } } }
    }.to_json

    post stripe_webhooks_url,
      params: payload,
      headers: signed_headers_for(payload).merge("Content-Type" => "application/json")

    assert_response :success
    assert_nil Subscription.find_by(stripe_subscription_id: "sub_999")
  end

  def addon_checkout_completed_payload(session_id: "cs_123", customer: "cus_123", metadata: { kind: "compliance_report_credit" })
    {
      type: "checkout.session.completed",
      data: {
        object: {
          id: session_id,
          customer: customer,
          mode: "payment",
          metadata: metadata
        }
      }
    }.to_json
  end

  test "grants a report credit for a completed addon checkout" do
    payload = addon_checkout_completed_payload

    assert_difference "ReportCredit.count", 1 do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
    credit = ReportCredit.find_by(stripe_checkout_session_id: "cs_123")
    assert_equal @organization, credit.organization
  end

  test "replaying the same addon checkout event does not grant a second credit" do
    payload = addon_checkout_completed_payload
    headers = signed_headers_for(payload).merge("Content-Type" => "application/json")

    post stripe_webhooks_url, params: payload, headers: headers

    assert_no_difference "ReportCredit.count" do
      post stripe_webhooks_url, params: payload, headers: headers
    end
  end

  test "ignores a checkout.session.completed for a subscription checkout, not just mode" do
    payload = {
      type: "checkout.session.completed",
      data: { object: { id: "cs_sub", customer: "cus_123", mode: "subscription", metadata: {} } }
    }.to_json

    assert_no_difference "ReportCredit.count" do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
  end

  test "ignores an addon checkout for a customer with no matching organization" do
    payload = addon_checkout_completed_payload(customer: "cus_unknown")

    assert_no_difference "ReportCredit.count" do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
  end

  test "grants 10 report credits for a completed bulk-pack addon checkout" do
    payload = addon_checkout_completed_payload(metadata: { kind: "compliance_report_credit", credit_quantity: "10" })

    assert_difference "ReportCredit.count", 10 do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
    credits = ReportCredit.where(stripe_checkout_session_id: "cs_123")
    assert_equal @organization, credits.first.organization
    assert_equal (1..10).to_a, credits.order(:sequence).pluck(:sequence)
  end

  test "replaying the same bulk-pack checkout event does not grant a second batch" do
    payload = addon_checkout_completed_payload(metadata: { kind: "compliance_report_credit", credit_quantity: "10" })
    headers = signed_headers_for(payload).merge("Content-Type" => "application/json")

    post stripe_webhooks_url, params: payload, headers: headers

    assert_no_difference "ReportCredit.count" do
      post stripe_webhooks_url, params: payload, headers: headers
    end
  end

  test "a White-Glove Setup checkout grants no report credit -- fulfillment is manual" do
    payload = addon_checkout_completed_payload(metadata: { kind: "white_glove_setup" })

    assert_no_difference "ReportCredit.count" do
      post stripe_webhooks_url,
        params: payload,
        headers: signed_headers_for(payload).merge("Content-Type" => "application/json")
    end

    assert_response :success
  end
end
