require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @endpoint = @organization.webhook_endpoints.create!(url: "https://8.8.8.8/h")
  end

  def build_delivery(**attrs)
    @endpoint.deliveries.create!(
      { event: "webhook.test", event_id: SecureRandom.uuid, payload: { "a" => 1 } }.merge(attrs)
    )
  end

  test "defaults to pending with zero attempts" do
    delivery = build_delivery
    assert delivery.pending?
    assert_equal 0, delivery.attempts
  end

  test "requires an event and event_id" do
    delivery = @endpoint.deliveries.build(event: nil, event_id: nil)
    assert_not delivery.valid?
    assert delivery.errors[:event].any?
    assert delivery.errors[:event_id].any?
  end

  test "replay? is true only when replayed_from is set" do
    original = build_delivery
    assert_not original.replay?

    replay = build_delivery(replayed_from: original)
    assert replay.replay?
    assert_equal original, replay.replayed_from
  end

  test "expired scope selects only rows past the retention window" do
    old = build_delivery
    old.update_column(:created_at, (WebhookDelivery::RETENTION + 1.day).ago)
    fresh = build_delivery

    assert_includes WebhookDelivery.expired, old
    assert_not_includes WebhookDelivery.expired, fresh
  end

  test "deleting the endpoint deletes its deliveries" do
    build_delivery
    assert_difference -> { WebhookDelivery.count }, -1 do
      @endpoint.destroy
    end
  end
end
