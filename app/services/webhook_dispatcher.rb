# Fan-out point for outbound event webhooks. Callers hand it an event name
# and a data hash; it wraps that in the standard envelope, records a
# WebhookDelivery row per subscribed endpoint, and enqueues one
# WebhookDeliveryJob to send it. A no-op unless the org is on a plan that
# includes webhooks and has at least one active endpoint, so it's safe to
# call unconditionally from the event sources (ExcursionNotifier,
# CustodyLogsController).
module WebhookDispatcher
  def self.publish(organization:, event:, data:)
    return unless organization&.webhooks_available?

    organization.webhook_endpoints.active.find_each do |endpoint|
      next unless endpoint.delivers?(event)

      envelope = { id: SecureRandom.uuid, event: event, created_at: Time.current.iso8601, data: data }
      delivery = endpoint.deliveries.create!(event: event, event_id: envelope[:id], payload: envelope.as_json)
      WebhookDeliveryJob.perform_later(delivery.id)
    end
  end
end
