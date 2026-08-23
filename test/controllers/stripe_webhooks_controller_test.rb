require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
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
  def subscription_event_payload(status: "active")
    {
      type: "customer.subscription.updated",
      data: {
        object: {
          id: "sub_123",
          customer: "cus_123",
          status: status,
          items: { data: [ { price: { unit_amount: 9900 }, current_period_end: 1.month.from_now.to_i } ] }
        }
      }
    }.to_json
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
end
