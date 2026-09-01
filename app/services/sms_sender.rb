# Thin wrapper over Twilio's REST client. Safe to call in any environment:
# with no credentials configured it raises NotConfigured (which the calling
# job logs and swallows) rather than trying to reach Twilio. Mirrors the
# "real endpoint, no-op until keys are set" pattern used for Stripe and SMTP.
#
# Env vars:
#   TWILIO_ACCOUNT_SID
#   TWILIO_AUTH_TOKEN
#   TWILIO_MESSAGING_FROM  -- either a "+1..." sender number or an "MG..."
#                             Messaging Service SID
class SmsSender
  class NotConfigured < StandardError; end
  class DeliveryFailed < StandardError; end

  def self.configured?
    ENV["TWILIO_ACCOUNT_SID"].present? &&
      ENV["TWILIO_AUTH_TOKEN"].present? &&
      ENV["TWILIO_MESSAGING_FROM"].present?
  end

  # Returns the Twilio message SID on success. Raises NotConfigured if no
  # credentials, DeliveryFailed for a Twilio-side rejection.
  def self.deliver(to:, body:)
    new.deliver(to: to, body: body)
  end

  def deliver(to:, body:)
    raise NotConfigured, "Twilio credentials are not set" unless self.class.configured?

    message = client.messages.create(sender_param.merge(to: to, body: body))
    message.sid
  rescue Twilio::REST::RestError => e
    raise DeliveryFailed, "Twilio rejected the message to #{to}: #{e.message}"
  end

  private

  def client
    @client ||= Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  end

  def sender_param
    from = ENV["TWILIO_MESSAGING_FROM"]
    from.start_with?("MG") ? { messaging_service_sid: from } : { from: from }
  end
end
