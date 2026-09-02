# Basic abuse protection for the public endpoints that matter most now
# that self-service signup is live: nothing throttled any of these before,
# so signup, login, and password reset could all be hit with unlimited
# automated requests. That's not just a security gap -- signup confirmation
# email currently goes out through a personal Gmail account (see
# config/initializers/devise.rb), which has its own daily sending cap and
# can flag the account for abuse-looking traffic. Throttling signup keeps
# a burst of spam signups from being the thing that takes out real email
# delivery.
#
# Uses Rails.cache (ActiveSupport::Cache::FileStore by default here) as the
# throttle store -- fine for a single-instance deployment; would need a
# shared store (e.g. Redis) if this app ever runs more than one web
# instance, since counters wouldn't be shared across processes.
#
# Deliberately does NOT throttle POST /stripe/webhooks: that endpoint is
# already protected by Stripe's own signature verification (see
# StripeWebhooksController), and Stripe retries failed/delayed deliveries,
# so a throttle there risks dropping real events during a legitimate burst
# (e.g. many subscriptions renewing around the same time) rather than
# stopping abuse.
class Rack::Attack
  throttle("logins/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # The second-factor challenge is the one place a correct password still
  # isn't enough -- without this, the 6-digit code could be brute-forced at
  # full request speed. Same shape as the login throttle above.
  throttle("two_factor/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/two_factor_challenge" && req.post?
  end

  # The enrollment (POST) and disable (DELETE) forms also verify a 6-digit
  # code -- throttle them the same way so an attacker with a stolen password
  # can't brute-force the code to enroll a device they control or to turn
  # two-factor off.
  throttle("two_factor_setup/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/two_factor_setup" && %w[POST DELETE].include?(req.request_method)
  end

  # Device telemetry ingest (POST /api/v1/gps). Real trackers in a fleet
  # commonly share one public IP -- carrier-grade NAT on cellular networks
  # puts every truck on the same wholesale address -- so the per-IP
  # backstop below is the wrong control here: a big enough fleet reporting
  # at a normal cadence would trip it. Throttle per device token instead,
  # at a rate far above any sane reporting interval, so one wedged device
  # can't flood us while a whole fleet reporting normally never notices.
  # Requests with no token fall through to the stricter anon throttle.
  throttle("gps_ingest/token", limit: 120, period: 1.minute) do |req|
    if req.path == "/api/v1/gps" && req.post?
      req.get_header("HTTP_X_DEVICE_TOKEN").presence || req.ip
    end
  end

  # A POST to the ingest endpoint with no device token is either a
  # misconfigured device or something probing for valid IMEIs. Keep those
  # on a tight per-IP leash regardless of the fleet-friendly limit above.
  throttle("gps_ingest/anon", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/gps" && req.post? && req.get_header("HTTP_X_DEVICE_TOKEN").blank?
  end

  # Public lead forms (request-a-call, DSCSA assessment). Same reasoning as
  # the signup throttle: a burst of spam submissions both fills the leads
  # inbox and can flag the sending Gmail account for abuse.
  throttle("lead_forms/ip", limit: 10, period: 1.hour) do |req|
    req.ip if %w[/request-a-call /dscsa-assessment].include?(req.path) && req.post?
  end

  # General backstop against basic flooding of any endpoint, independent of
  # the specific throttles above. Device telemetry ingest is exempt -- it
  # has its own per-token and anon throttles (see gps_ingest/*), and a
  # NAT'd fleet's combined volume would otherwise trip this per-IP limit.
  throttle("requests/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path == "/api/v1/gps" && req.post?
  end

  self.throttled_responder = lambda do |request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests. Please try again shortly." }.to_json ] ]
  end
end
