require "test_helper"

class WebhookDispatcherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  PUBLIC_URL = "https://8.8.8.8/a"

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  def subscribe(tier)
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_#{tier}", tier: tier)
  end

  test "no-op when the plan doesn't include webhooks, even with an endpoint" do
    subscribe("pro")
    @organization.webhook_endpoints.create!(url: PUBLIC_URL)

    assert_no_enqueued_jobs only: WebhookDeliveryJob do
      WebhookDispatcher.publish(organization: @organization, event: "custody.recorded", data: {})
    end
  end

  test "enqueues one delivery per active endpoint on the Compliance plan" do
    subscribe("compliance")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/one")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/two")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/off", active: false)

    assert_enqueued_jobs 2, only: WebhookDeliveryJob do
      WebhookDispatcher.publish(organization: @organization, event: "custody.recorded", data: { lot_number: "LOT-1" })
    end
  end

  test "only delivers to endpoints subscribed to the event (empty filter = all)" do
    subscribe("compliance")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/all")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/custody-only", subscribed_events: %w[custody.recorded])
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/excursions", subscribed_events: %w[excursion.started excursion.resolved])

    assert_enqueued_jobs 2, only: WebhookDeliveryJob do
      WebhookDispatcher.publish(organization: @organization, event: "excursion.started", data: {})
    end
  end

  test "records a WebhookDelivery per endpoint and enqueues the job with its id" do
    subscribe("compliance")
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)

    assert_difference -> { WebhookDelivery.count }, 1 do
      WebhookDispatcher.publish(organization: @organization, event: "excursion.started", data: { lot_number: "LOT-9" })
    end

    delivery = endpoint.deliveries.sole
    assert delivery.pending?
    assert_equal "excursion.started", delivery.event
    assert_equal delivery.event_id, delivery.payload["id"]
    assert_equal "excursion.started", delivery.payload["event"]
    assert_equal "LOT-9", delivery.payload.dig("data", "lot_number")

    job = enqueued_jobs.find { |j| j["job_class"] == "WebhookDeliveryJob" }
    assert_equal [ delivery.id ], job["arguments"]
  end

  test "no delivery rows are written when the plan doesn't include webhooks" do
    subscribe("pro")
    @organization.webhook_endpoints.create!(url: PUBLIC_URL)

    assert_no_difference -> { WebhookDelivery.count } do
      WebhookDispatcher.publish(organization: @organization, event: "custody.recorded", data: {})
    end
  end
end
