require "net/http"

# POSTs one WebhookDelivery's envelope to its endpoint, signed with that
# endpoint's secret, and records the outcome back on the delivery row
# (status, HTTP code, attempts, timing). Retries transient failures
# (timeouts, 5xx, 429) with backoff; a 4xx is treated as "the receiver
# rejected it, don't keep trying". The endpoint's consecutive_failures is
# bumped once per *delivery* that ultimately fails, not once per retry --
# so AUTO_DISABLE_AFTER counts real dead deliveries.
class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  TIMEOUT = 10 # seconds, connect and read
  RETRYABLE = [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError ].freeze

  class RetryableResponse < StandardError; end

  discard_on ActiveJob::DeserializationError

  retry_on(*RETRYABLE, RetryableResponse, wait: :polynomially_longer, attempts: 5) do |job, error|
    delivery = WebhookDelivery.find_by(id: job.arguments.first)
    next unless delivery

    delivery.update!(status: :failed, error: error.message, completed_at: Time.current)
    delivery.webhook_endpoint.record_failure!(error.message)
  end

  def perform(delivery_id)
    delivery = WebhookDelivery.find_by(id: delivery_id)
    return unless delivery

    endpoint = delivery.webhook_endpoint
    return unless endpoint.active?

    delivery.increment!(:attempts)

    unless WebhookEndpoint.public_https_url?(endpoint.url)
      finish_failed(delivery, endpoint, "URL no longer resolves to a public HTTPS address")
      return
    end

    body = delivery.payload.to_json
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = deliver(endpoint, delivery.event, body)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    code = response.code.to_i
    delivery.update!(response_status: code, duration_ms: duration_ms)

    if code.between?(200, 299)
      delivery.update!(status: :succeeded, error: nil, completed_at: Time.current)
      endpoint.record_success!
    elsif code == 429 || code.between?(500, 599)
      delivery.update!(error: "HTTP #{code}")
      raise RetryableResponse, "HTTP #{code}"
    else
      finish_failed(delivery, endpoint, "HTTP #{code}")
    end
  end

  private

  def finish_failed(delivery, endpoint, message)
    delivery.update!(status: :failed, error: message, completed_at: Time.current)
    endpoint.record_failure!(message)
  end

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
