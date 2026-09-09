module Ops
  # On-demand Postmark health probe, run only when an operator clicks
  # "Check Postmark" on /ops. Unlike Ops::Diagnostics -- which reads local
  # env/DB state and is safe on every page load -- this makes live calls
  # to the Postmark API, so it must not run automatically.
  #
  # It closes the gap the env-var "Delivery method" check can't see: a
  # POSTMARK_API_TOKEN that is set but wrong, revoked, or from the wrong
  # server. server_info raises Postmark::InvalidApiKeyError on a bad
  # token; a good token also gets us the last 24h of outbound counts
  # (sent / bounced / spam) so a delivery problem is visible here instead
  # of only in the Postmark dashboard.
  class PostmarkCheck
    Result = Data.define(:ok, :message)

    def self.call = new.call

    def call
      token = ENV["POSTMARK_API_TOKEN"].presence
      return not_configured unless token

      client = Postmark::ApiClient.new(token)
      name = client.server_info[:name]
      stats = client.get_stats_totals(fromdate: 1.day.ago.to_date.iso8601, todate: Date.current.iso8601)

      Result.new(ok: true, message:
        %(Postmark OK -- token valid for server "#{name}". ) +
        %(Last 24h: #{stats[:sent].to_i} sent, #{stats[:bounced].to_i} bounced, #{stats[:spam_complaints].to_i} spam complaints.))
    rescue Postmark::Error => e
      Result.new(ok: false, message: "Postmark check failed: #{e.class}: #{e.message}")
    end

    private

    def not_configured
      Result.new(ok: false, message:
        "POSTMARK_API_TOKEN is not set -- Postmark is not the active mail transport. Nothing to check.")
    end
  end
end
