require "test_helper"

class WebhookEndpointsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  PUBLIC_URL = "https://8.8.8.8/hooks/pt"

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "d@example.com", password: "password123!", organization: @organization, role: "dispatcher")
  end

  def enable_webhooks
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_c", tier: "compliance")
  end

  test "requires authentication" do
    get webhook_endpoints_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows the upgrade prompt when the plan doesn't include webhooks" do
    sign_in @dispatcher
    get webhook_endpoints_url

    assert_response :success
    assert_match "included on the", response.body
    assert_select "a[href=?]", billing_path
  end

  test "an admin on the Compliance plan can add an endpoint" do
    enable_webhooks
    sign_in @admin

    assert_difference -> { @organization.webhook_endpoints.count }, 1 do
      post webhook_endpoints_url, params: { webhook_endpoint: { url: PUBLIC_URL } }
    end
    assert_redirected_to webhook_endpoints_path
    assert @organization.webhook_endpoints.last.signing_secret.present?
  end

  test "a bad URL re-renders with the error" do
    enable_webhooks
    sign_in @admin

    assert_no_difference -> { WebhookEndpoint.count } do
      post webhook_endpoints_url, params: { webhook_endpoint: { url: "http://10.0.0.1/x" } }
    end
    assert_response :unprocessable_content
    assert_match "HTTPS URL that resolves to a public address", response.body
  end

  test "a non-admin cannot add an endpoint" do
    enable_webhooks
    sign_in @dispatcher

    assert_no_difference -> { WebhookEndpoint.count } do
      post webhook_endpoints_url, params: { webhook_endpoint: { url: PUBLIC_URL } }
    end
    assert_redirected_to webhook_endpoints_path
  end

  test "adding is refused without the Compliance plan" do
    sign_in @admin
    assert_no_difference -> { WebhookEndpoint.count } do
      post webhook_endpoints_url, params: { webhook_endpoint: { url: PUBLIC_URL } }
    end
    assert_redirected_to webhook_endpoints_path
  end

  test "an admin can send a test event, remove, and re-enable an endpoint" do
    enable_webhooks
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL, active: false, consecutive_failures: WebhookEndpoint::AUTO_DISABLE_AFTER)
    sign_in @admin

    assert_enqueued_jobs 1, only: WebhookDeliveryJob do
      post test_webhook_endpoint_url(endpoint)
    end

    post enable_webhook_endpoint_url(endpoint)
    assert endpoint.reload.active?
    assert_equal 0, endpoint.consecutive_failures

    assert_difference -> { WebhookEndpoint.count }, -1 do
      delete webhook_endpoint_url(endpoint)
    end
  end

  test "an admin can add an endpoint with an event filter" do
    enable_webhooks
    sign_in @admin

    post webhook_endpoints_url, params: {
      webhook_endpoint: { url: PUBLIC_URL, subscribed_events: [ "custody.recorded", "" ] }
    }
    assert_equal %w[custody.recorded], @organization.webhook_endpoints.last.subscribed_events
  end

  test "the index renders a per-event filter form for each endpoint" do
    enable_webhooks
    @organization.webhook_endpoints.create!(url: PUBLIC_URL, subscribed_events: %w[custody.recorded])
    sign_in @admin

    get webhook_endpoints_url
    assert_response :success
    assert_select "input[type=checkbox][name=?][value=?][checked=checked]", "webhook_endpoint[subscribed_events][]", "custody.recorded"
    assert_select "input[type=checkbox][name=?][value=?]:not([checked])", "webhook_endpoint[subscribed_events][]", "excursion.started"
  end

  test "an admin can change an endpoint's event filter, and clear it back to all" do
    enable_webhooks
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)
    sign_in @admin

    patch webhook_endpoint_url(endpoint), params: {
      webhook_endpoint: { subscribed_events: [ "excursion.started", "" ] }
    }
    assert_equal %w[excursion.started], endpoint.reload.subscribed_events

    patch webhook_endpoint_url(endpoint), params: { webhook_endpoint: { subscribed_events: [ "" ] } }
    assert endpoint.reload.all_events?
  end

  test "a non-admin cannot change an endpoint's event filter" do
    enable_webhooks
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL, subscribed_events: %w[custody.recorded])
    sign_in @dispatcher

    patch webhook_endpoint_url(endpoint), params: { webhook_endpoint: { subscribed_events: [ "excursion.started" ] } }
    assert_redirected_to webhook_endpoints_path
    assert_equal %w[custody.recorded], endpoint.reload.subscribed_events
  end

  test "one organization cannot touch another's endpoint" do
    other = Organization.create!(name: "Other Pharma")
    theirs = other.webhook_endpoints.create!(url: PUBLIC_URL)
    enable_webhooks
    sign_in @admin

    delete webhook_endpoint_url(theirs)
    assert_response :not_found
    assert WebhookEndpoint.exists?(theirs.id)
  end
end
