# config/environments/production.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings here override config/application.rb.

  # Production code is loaded once at boot and not reloaded per request.
  config.enable_reloading = false
  config.eager_load = true

  # Do not show detailed exception pages to users.
  config.consider_all_requests_local = false

  # Allow Rails to serve files in public/ if needed.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Logging
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [ :request_id ]
  # ActiveSupport::TaggedLogging.logger(*args) forwards its arguments
  # straight to ActiveSupport::Logger.new(*args) internally -- it wants the
  # raw args you'd give Logger.new (a filename/IO), not an already-built
  # Logger. Passing it a Logger here made it try to File.open() a Logger
  # object, crashing on every boot. This has never actually run before:
  # nothing pointed a live Render deploy at the real Rails app until now
  # (see the Start Command fix in Render's dashboard).
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)

  # Render terminates TLS before traffic reaches Puma.
  config.force_ssl = false

  # Required so Action Mailer (used by Devise for password-reset, account
  # -unlock, and signup-confirmation emails) can build absolute URLs. Set
  # APP_HOST to the real production domain in the deploy environment.
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com"), protocol: "https" }

  # No real delivery method was ever configured here -- Rails' unconfigured
  # default (:smtp with no smtp_settings) raises on every send attempt, so
  # password-reset/unlock emails have never actually gone out in production,
  # and self-service signup's confirmation email (see
  # Users::RegistrationsController) would fail the same way. Falls back to
  # a safe no-op until real SMTP credentials are set as Render env vars,
  # rather than crashing every request that tries to send mail.
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      domain: ENV.fetch("APP_HOST", "example.com"),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  else
    config.action_mailer.delivery_method = :test
  end
  config.action_mailer.perform_deliveries = true
  # false so a mail-provider outage (SMTP auth rejected, connection refused,
  # timeout) degrades to "the account was created but the email didn't send"
  # instead of a 500 page mid-signup. Was briefly flipped to true to
  # diagnose a real failure (an M365 SMTP timeout -- see git history on this
  # line); that confirmed Rails does NOT log anything on its own when this
  # is false, so User#send_devise_notification now explicitly rescues and
  # logs delivery failures instead of relying on this flag for visibility.
  config.action_mailer.raise_delivery_errors = false

  # Route health checks to a lightweight endpoint.
  config.silence_healthcheck_path = "/up"

  # Keep normal Rails production behavior.
  config.active_record.dump_schema_after_migration = false
  config.active_record.async_query_executor = :global_thread_pool

  # Durable background jobs (temperature-excursion alert emails, and
  # whatever gets queued next). Solid Queue's tables live in the primary
  # database (no separate `queue` DB), so no connects_to override is
  # needed. The worker runs inside Puma via `plugin :solid_queue` in
  # config/puma.rb -- no separate process to deploy. config/queue.yml
  # controls its concurrency; config/recurring.yml its scheduled tasks.
  config.active_job.queue_adapter = :solid_queue

  # Required for signed cookies, encrypted credentials, etc.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")

  # Do not expose secrets in logs:
  # Never add DATABASE_URL here.
end
