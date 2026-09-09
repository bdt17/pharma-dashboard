require "test_helper"

module Ops
  class PostmarkCheckTest < ActiveSupport::TestCase
    def with_env(overrides)
      original = ENV.to_h
      overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      yield
    ensure
      ENV.replace(original)
    end

    # A stand-in for Postmark::ApiClient. Minitest's stub can't easily
    # intercept .new, so PostmarkCheck is tested by stubbing the class's
    # :new to return one of these.
    class FakeClient
      def initialize(server_info: { name: "Pharma Transport" }, stats: {}, raise_on: nil)
        @server_info = server_info
        @stats = { sent: 0, bounced: 0, spam_complaints: 0 }.merge(stats)
        @raise_on = raise_on
      end

      def server_info
        raise @raise_on if @raise_on
        @server_info
      end

      def get_stats_totals(*) = @stats
    end

    test "reports not-configured when POSTMARK_API_TOKEN is unset" do
      with_env("POSTMARK_API_TOKEN" => nil) do
        result = Ops::PostmarkCheck.call
        assert_not result.ok
        assert_match "not set", result.message
      end
    end

    test "reports ok with recent counts when the token is valid" do
      with_env("POSTMARK_API_TOKEN" => "pm-token") do
        fake = FakeClient.new(server_info: { name: "Pharma Transport" },
                              stats: { sent: 12, bounced: 1, spam_complaints: 0 })
        Postmark::ApiClient.stub(:new, fake) do
          result = Ops::PostmarkCheck.call
          assert result.ok
          assert_match %(server "Pharma Transport"), result.message
          assert_match "12 sent, 1 bounced, 0 spam complaints", result.message
        end
      end
    end

    test "reports failure on an invalid token without raising" do
      with_env("POSTMARK_API_TOKEN" => "bad-token") do
        fake = FakeClient.new(raise_on: Postmark::InvalidApiKeyError.new("401"))
        Postmark::ApiClient.stub(:new, fake) do
          result = Ops::PostmarkCheck.call
          assert_not result.ok
          assert_match "Postmark check failed", result.message
          assert_match "InvalidApiKeyError", result.message
        end
      end
    end
  end
end
