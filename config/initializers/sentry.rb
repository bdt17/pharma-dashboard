# Error tracking -- a no-op until SENTRY_DSN is set as a Render env var,
# the same "safe until configured" pattern as Stripe/SMTP/Twilio (see
# their own initializers/config comments). Added after a real production
# incident (an M365 SMTP timeout) was found only by manually clicking a
# button on /ops -- nothing the app itself had ever surfaced. See
# Ops::Diagnostics for the matching /ops visibility check.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = Rails.env

    # No performance/APM tracing -- this is error tracking only, kept
    # deliberately cheap. Bump traces_sample_rate above 0 later if
    # request-level performance data is ever actually wanted.
    config.traces_sample_rate = 0.0

    # Explicit, not just relying on the gem's own default: this app
    # handles pharmacy operator PII (names, emails, phone numbers) and
    # compliance data -- an error report should say what broke, not carry
    # request bodies or user attributes along with it.
    config.send_default_pii = false
  end
end
