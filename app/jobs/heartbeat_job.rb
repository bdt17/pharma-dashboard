# Periodic liveness check-in to Sentry's Cron Monitors. Every real
# outage this app has had (two SMTP failures, Stripe pagination, silent
# mail bugs) was found by a human poking the live site -- nothing the app
# ran told anyone. This is the backstop for a whole-app or whole-queue
# outage: a failed deploy, a crash loop, a wedged Solid Queue. If this
# job stops checking in, Sentry notices the missing check-in after the
# grace period and alerts, without anything else having to be watching.
#
# No-op until SENTRY_DSN is set (see config/initializers/sentry.rb):
# with Sentry uninitialized, Sentry.capture_check_in returns nil and the
# MonitorCheckIns mixin below does nothing. Scheduled every 5 minutes in
# config/recurring.yml.
class HeartbeatJob < ApplicationJob
  queue_as :default

  include Sentry::Cron::MonitorCheckIns
  sentry_monitor_check_ins(
    slug: "pharma-heartbeat",
    monitor_config: Sentry::Cron::MonitorConfig.from_interval(5, :minute, checkin_margin: 2, max_runtime: 2)
  )

  # Intentionally empty. The value is the check-in the MonitorCheckIns
  # mixin sends to Sentry around this method, not anything done here.
  def perform; end
end
