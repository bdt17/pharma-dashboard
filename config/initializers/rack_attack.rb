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

  # General backstop against basic flooding of any endpoint, independent of
  # the specific throttles above.
  throttle("requests/ip", limit: 300, period: 5.minutes, &:ip)

  self.throttled_responder = lambda do |request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests. Please try again shortly." }.to_json ] ]
  end
end
