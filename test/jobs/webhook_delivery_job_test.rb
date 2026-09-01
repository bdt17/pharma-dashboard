require "test_helper"

class WebhookDeliveryJobTest < ActiveJob::TestCase
  PUBLIC_URL = "https://8.8.8.8/hooks/pt"

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)
    @envelope = { "id" => "evt_1", "event" => "webhook.test", "data" => { "message" => "hi" } }
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

  test "a 2xx response signs the body and records success" do
    with_http(200) do |http|
      WebhookDeliveryJob.perform_now(@endpoint.id, "webhook.test", @envelope)

      req = http.last_request
      assert_equal @envelope.to_json, req.body
      assert_equal "webhook.test", req["X-PharmaTransport-Event"]
      assert_equal "sha256=#{@endpoint.sign(@envelope.to_json)}", req["X-PharmaTransport-Signature"]
    end

    assert @endpoint.reload.last_success_at
    assert_equal 0, @endpoint.consecutive_failures
  end

  test "a 4xx response records a failure and does not raise (no retry)" do
    with_http(422) do
      assert_nothing_raised { WebhookDeliveryJob.perform_now(@endpoint.id, "webhook.test", @envelope) }
    end
    assert_equal 1, @endpoint.reload.consecutive_failures
    assert_equal "HTTP 422", @endpoint.last_error
  end

  test "a 5xx response schedules a retry and is not counted as a permanent failure yet" do
    with_http(503) do
      assert_enqueued_jobs 1, only: WebhookDeliveryJob do
        WebhookDeliveryJob.perform_now(@endpoint.id, "webhook.test", @envelope)
      end
    end
    assert_equal 0, @endpoint.reload.consecutive_failures
  end

  test "records a permanent failure once retries are exhausted" do
    with_http(500) do
      perform_enqueued_jobs do
        WebhookDeliveryJob.perform_later(@endpoint.id, "webhook.test", @envelope)
      rescue WebhookDeliveryJob::RetryableResponse
        # ActiveJob re-raises the last error after exhausting retries
      end
    end
    assert_operator @endpoint.reload.consecutive_failures, :>=, 1
    assert_equal "HTTP 500", @endpoint.last_error
  end

  test "does nothing for an inactive endpoint" do
    @endpoint.update!(active: false)
    Net::HTTP.stub(:new, ->(*) { raise "should not connect" }) do
      assert_nothing_raised { WebhookDeliveryJob.perform_now(@endpoint.id, "webhook.test", @envelope) }
    end
  end

  test "records a failure without connecting when the URL is no longer public" do
    @endpoint.update_column(:url, "https://10.0.0.9/x")
    Net::HTTP.stub(:new, ->(*) { raise "should not connect" }) do
      WebhookDeliveryJob.perform_now(@endpoint.id, "webhook.test", @envelope)
    end
    assert_equal 1, @endpoint.reload.consecutive_failures
  end
end
