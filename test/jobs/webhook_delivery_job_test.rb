require "test_helper"

class WebhookDeliveryJobTest < ActiveJob::TestCase
  PUBLIC_URL = "https://8.8.8.8/hooks/pt"

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)
    @envelope = { "id" => "evt_1", "event" => "webhook.test", "created_at" => "2026-09-01T00:00:00Z",
                  "data" => { "message" => "hi" } }
    @delivery = @endpoint.deliveries.create!(event: "webhook.test", event_id: "evt_1", payload: @envelope)
  end

  # Stand-in for Net::HTTP: records the request it's handed, returns a
  # response with the code the test wants.
  class FakeHTTP
    attr_accessor :use_ssl, :open_timeout, :read_timeout
    attr_reader :last_request

    def initialize(code) = (@code = code)
    def request(req)
      @last_request = req
      Struct.new(:code).new(@code.to_s)
    end
  end

  def with_http(code)
    fake = FakeHTTP.new(code)
    Net::HTTP.stub(:new, ->(*) { fake }) { yield fake }
  end

  test "a 2xx response signs the body and records success on the delivery" do
    with_http(200) do |http|
      WebhookDeliveryJob.perform_now(@delivery.id)

      req = http.last_request
      # jsonb doesn't preserve key order, so compare parsed, and check the
      # signature against the bytes actually sent.
      assert_equal @envelope, JSON.parse(req.body)
      assert_equal "webhook.test", req["X-PharmaTransport-Event"]
      assert_equal "sha256=#{@endpoint.sign(req.body)}", req["X-PharmaTransport-Signature"]
    end

    @delivery.reload
    assert @delivery.succeeded?
    assert_equal 200, @delivery.response_status
    assert_equal 1, @delivery.attempts
    assert @delivery.completed_at
    assert_not_nil @delivery.duration_ms
    assert @endpoint.reload.last_success_at
    assert_equal 0, @endpoint.consecutive_failures
  end

  test "a 4xx response marks the delivery failed and does not raise (no retry)" do
    with_http(422) do
      assert_nothing_raised { WebhookDeliveryJob.perform_now(@delivery.id) }
    end
    @delivery.reload
    assert @delivery.failed?
    assert_equal "HTTP 422", @delivery.error
    assert_equal 1, @endpoint.reload.consecutive_failures
  end

  test "a 5xx response schedules a retry and leaves the delivery pending" do
    with_http(503) do
      assert_enqueued_jobs 1, only: WebhookDeliveryJob do
        WebhookDeliveryJob.perform_now(@delivery.id)
      end
    end
    @delivery.reload
    assert @delivery.pending?
    assert_equal "HTTP 503", @delivery.error
    assert_equal 0, @endpoint.reload.consecutive_failures
  end

  test "marks the delivery failed once retries are exhausted" do
    with_http(500) do
      perform_enqueued_jobs do
        WebhookDeliveryJob.perform_later(@delivery.id)
      rescue WebhookDeliveryJob::RetryableResponse
        # ActiveJob re-raises the last error after exhausting retries
      end
    end
    @delivery.reload
    assert @delivery.failed?
    assert_equal "HTTP 500", @delivery.error
    assert_operator @endpoint.reload.consecutive_failures, :>=, 1
    assert_operator @delivery.attempts, :>=, 2
  end

  test "does nothing for an inactive endpoint" do
    @endpoint.update!(active: false)
    Net::HTTP.stub(:new, ->(*) { raise "should not connect" }) do
      assert_nothing_raised { WebhookDeliveryJob.perform_now(@delivery.id) }
    end
    assert @delivery.reload.pending?
  end

  test "does nothing when the delivery row is gone" do
    id = @delivery.id
    @delivery.destroy
    Net::HTTP.stub(:new, ->(*) { raise "should not connect" }) do
      assert_nothing_raised { WebhookDeliveryJob.perform_now(id) }
    end
  end

  test "marks failed without connecting when the URL is no longer public" do
    @endpoint.update_column(:url, "https://10.0.0.9/x")
    Net::HTTP.stub(:new, ->(*) { raise "should not connect" }) do
      WebhookDeliveryJob.perform_now(@delivery.id)
    end
    assert @delivery.reload.failed?
    assert_equal 1, @endpoint.reload.consecutive_failures
  end
end
