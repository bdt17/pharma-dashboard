require "test_helper"

class WebhookEndpointTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  # A public IP literal so URL validation never has to hit real DNS.
  PUBLIC_URL = "https://8.8.8.8/hooks/pharma"

  test "generates a signing secret on create and signs a body with it" do
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)

    assert endpoint.signing_secret.start_with?("whsec_")
    expected = OpenSSL::HMAC.hexdigest("SHA256", endpoint.signing_secret, "{}")
    assert_equal expected, endpoint.sign("{}")
  end

  test "rejects a non-HTTPS URL" do
    endpoint = @organization.webhook_endpoints.build(url: "http://8.8.8.8/hook")
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:url].join, "HTTPS"
  end

  test "rejects URLs that resolve to loopback, private, or link-local addresses" do
    %w[
      https://127.0.0.1/x
      https://10.1.2.3/x
      https://192.168.0.1/x
      https://172.16.5.5/x
      https://169.254.169.254/latest/meta-data
      https://[::1]/x
    ].each do |bad|
      assert_not @organization.webhook_endpoints.build(url: bad).valid?, "#{bad} should be rejected"
    end
  end

  test "accepts a public HTTPS URL" do
    assert @organization.webhook_endpoints.build(url: PUBLIC_URL).valid?
  end

  test "accepts a public HTTPS URL that resolves via DNS" do
    Resolv.stub(:getaddresses, ->(_host) { [ "93.184.216.34" ] }) do
      assert @organization.webhook_endpoints.build(url: "https://hooks.example.com/pt").valid?
    end
  end

  test "the same URL can't be registered twice for one organization" do
    @organization.webhook_endpoints.create!(url: PUBLIC_URL)
    dupe = @organization.webhook_endpoints.build(url: PUBLIC_URL)
    assert_not dupe.valid?
    assert_includes dupe.errors[:url].join, "already been taken"
  end

  test "delivers? respects the subscribed_events filter" do
    all = @organization.webhook_endpoints.create!(url: "https://8.8.8.8/all")
    assert all.delivers?("excursion.started")
    assert all.delivers?("custody.recorded")

    filtered = @organization.webhook_endpoints.create!(url: "https://8.8.8.8/f", subscribed_events: %w[custody.recorded])
    assert filtered.delivers?("custody.recorded")
    assert_not filtered.delivers?("excursion.started")
    # webhook.test always goes through so the Send-test button keeps working
    assert filtered.delivers?("webhook.test")
  end

  test "normalizes subscribed_events -- drops blanks, de-dupes" do
    endpoint = @organization.webhook_endpoints.create!(
      url: "https://8.8.8.8/n", subscribed_events: [ "", "custody.recorded", "custody.recorded", "" ]
    )
    assert_equal %w[custody.recorded], endpoint.subscribed_events
    assert_not endpoint.all_events?
  end

  test "rejects an unknown event name in the filter" do
    endpoint = @organization.webhook_endpoints.build(url: PUBLIC_URL, subscribed_events: %w[custody.recorded not.a.real.event])
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:subscribed_events].join, "not.a.real.event"
  end

  test "record_failure! auto-disables after the threshold and record_success! clears it" do
    endpoint = @organization.webhook_endpoints.create!(url: PUBLIC_URL)

    (WebhookEndpoint::AUTO_DISABLE_AFTER - 1).times { endpoint.record_failure!("HTTP 500") }
    assert endpoint.active?

    endpoint.record_failure!("HTTP 500")
    assert_not endpoint.active?
    assert endpoint.auto_disabled?

    endpoint.update!(active: true)
    endpoint.record_success!
    assert_equal 0, endpoint.consecutive_failures
    assert_nil endpoint.last_error
  end
end
