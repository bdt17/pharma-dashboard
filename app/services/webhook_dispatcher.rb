# Fan-out point for outbound event webhooks. Callers hand it an event name
# and a data hash; it wraps that in the standard envelope and enqueues one
# WebhookDeliveryJob per active endpoint the organization has. A no-op
# unless the org is on a plan that includes webhooks and has at least one
# active endpoint, so it's safe to call unconditionally from the event
# sources (ExcursionNotifier, CustodyLogsController).
module WebhookDispatcher
  def self.publish(organization:, event:, data:)
    return unless organization&.webhooks_available?

    envelope = { id: SecureRandom.uuid, event: event, created_at: Time.current.iso8601, data: data }

    organization.webhook_endpoints.active.find_each do |endpoint|
      WebhookDeliveryJob.perform_later(endpoint.id, event, envelope)
    end
  end
end
