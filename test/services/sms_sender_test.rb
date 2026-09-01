require "test_helper"

class SmsSenderTest < ActiveSupport::TestCase
  ENV_KEYS = %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_MESSAGING_FROM].freeze

  setup do
    @saved = ENV_KEYS.index_with { |k| ENV[k] }
  end

  teardown do
    @saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def configure(from: "+15550001111")
    ENV["TWILIO_ACCOUNT_SID"] = "AC_test"
    ENV["TWILIO_AUTH_TOKEN"] = "token_test"
    ENV["TWILIO_MESSAGING_FROM"] = from
  end

  test "configured? requires all three env vars" do
    ENV_KEYS.each { |k| ENV.delete(k) }
    assert_not SmsSender.configured?

    configure
    assert SmsSender.configured?

    ENV.delete("TWILIO_AUTH_TOKEN")
    assert_not SmsSender.configured?
  end

  test "deliver raises NotConfigured when credentials are missing" do
    ENV_KEYS.each { |k| ENV.delete(k) }
    assert_raises(SmsSender::NotConfigured) do
      SmsSender.deliver(to: "+14155550100", body: "hi")
    end
  end

  test "deliver passes a plain number through as `from`" do
    configure(from: "+15550001111")
    fake_messages = Minitest::Mock.new
    fake_messages.expect(:create, Struct.new(:sid).new("SM123"),
      [ { from: "+15550001111", to: "+14155550100", body: "hi" } ])
    fake_client = Struct.new(:messages).new(fake_messages)

    Twilio::REST::Client.stub(:new, fake_client) do
      assert_equal "SM123", SmsSender.deliver(to: "+14155550100", body: "hi")
    end
    fake_messages.verify
  end

  test "deliver uses messaging_service_sid when the from value is an MG SID" do
    configure(from: "MG0000000000")
    fake_messages = Minitest::Mock.new
    fake_messages.expect(:create, Struct.new(:sid).new("SM999"),
      [ { messaging_service_sid: "MG0000000000", to: "+14155550100", body: "hi" } ])
    fake_client = Struct.new(:messages).new(fake_messages)

    Twilio::REST::Client.stub(:new, fake_client) do
      assert_equal "SM999", SmsSender.deliver(to: "+14155550100", body: "hi")
    end
    fake_messages.verify
  end
end
