require "test_helper"

class WebhookDeliveriesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "d@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_c", tier: "compliance")
    @endpoint = @organization.webhook_endpoints.create!(url: "https://8.8.8.8/h")
    @delivery = @endpoint.deliveries.create!(
      event: "custody.recorded", event_id: "evt_abc",
      payload: { "id" => "evt_abc", "event" => "custody.recorded", "data" => { "lot_number" => "LOT-1" } },
      status: "failed", response_status: 500, error: "HTTP 500", attempts: 5
    )
  end

  test "requires authentication" do
    get webhook_endpoint_deliveries_url(@endpoint), headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "any member of the org can view the log" do
    sign_in @dispatcher
    get webhook_endpoint_deliveries_url(@endpoint)

    assert_response :success
    assert_match "custody.recorded", response.body
    assert_match "HTTP 500", response.body
  end

  test "the log is scoped to the current organization" do
    other = Organization.create!(name: "Other Pharma")
    theirs = other.webhook_endpoints.create!(url: "https://8.8.8.8/x")
    sign_in @admin

    get webhook_endpoint_deliveries_url(theirs)
    assert_response :not_found
  end

  test "an admin can re-send a delivery, creating a linked pending row" do
    sign_in @admin

    assert_difference -> { @endpoint.deliveries.count }, 1 do
      assert_enqueued_jobs 1, only: WebhookDeliveryJob do
        post replay_webhook_endpoint_delivery_url(@endpoint, @delivery)
      end
    end

    replay = @endpoint.deliveries.order(:created_at).last
    assert replay.pending?
    assert_equal @delivery, replay.replayed_from
    assert_equal @delivery.event_id, replay.event_id
    assert_equal @delivery.payload, replay.payload
    assert_redirected_to webhook_endpoint_deliveries_path(@endpoint)
  end

  test "a non-admin cannot re-send a delivery" do
    sign_in @dispatcher

    assert_no_difference -> { @endpoint.deliveries.count } do
      post replay_webhook_endpoint_delivery_url(@endpoint, @delivery)
    end
    assert_redirected_to webhook_endpoint_deliveries_path(@endpoint)
  end

  test "cannot replay another org's delivery" do
    other = Organization.create!(name: "Other Pharma")
    theirs = other.webhook_endpoints.create!(url: "https://8.8.8.8/x")
    theirs_delivery = theirs.deliveries.create!(event: "webhook.test", event_id: "evt_z", payload: {})
    sign_in @admin

    post replay_webhook_endpoint_delivery_url(theirs, theirs_delivery)
    assert_response :not_found
  end
end
