require "net/http"

# POSTs one event envelope to one endpoint, signed with that endpoint's
# secret. Retries transient failures (timeouts, 5xx, 429) with backoff;
# a 4xx is treated as "the receiver rejected it, don't keep trying".
# consecutive_failures is bumped once per *event* that ultimately fails,
# not once per retry -- so AUTO_DISABLE_AFTER counts real dead deliveries.
class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  TIMEOUT = 10 # seconds, connect and read
  RETRYABLE = [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError ].freeze

  class RetryableResponse < StandardError; end

  discard_on ActiveJob::DeserializationError

  retry_on(*RETRYABLE, RetryableResponse, wait: :polynomially_longer, attempts: 5) do |job, error|
    endpoint = WebhookEndpoint.find_by(id: job.arguments.first)
    endpoint&.record_failure!(error.message)
  end

  def perform(endpoint_id, event, envelope)
    endpoint = WebhookEndpoint.find_by(id: endpoint_id)
    return unless endpoint&.active?

    unless WebhookEndpoint.public_https_url?(endpoint.url)
      endpoint.record_failure!("URL no longer resolves to a public HTTPS address")
      return
    end

    body = envelope.to_json
    response = deliver(endpoint, event, body)
    code = response.code.to_i

    if code.between?(200, 299)
      endpoint.record_success!
    elsif code == 429 || code.between?(500, 599)
      raise RetryableResponse, "HTTP #{code}"
    else
      endpoint.record_failure!("HTTP #{code}")
    end
  end

  private

  def deliver(endpoint, event, body)
    uri = URI.parse(endpoint.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = body
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "PharmaTransport-Webhooks/1"
    request["X-PharmaTransport-Event"] = event
    request["X-PharmaTransport-Signature"] = "sha256=#{endpoint.sign(body)}"

    http.request(request)
  end
end
