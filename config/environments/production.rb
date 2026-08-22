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

  # Required so Action Mailer (used by Devise for password-reset and account
  # -unlock emails) can build absolute URLs. Set APP_HOST to the real
  # production domain in the deploy environment.
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com"), protocol: "https" }

  # Route health checks to a lightweight endpoint.
  config.silence_healthcheck_path = "/up"

  # Keep normal Rails production behavior.
  config.active_record.dump_schema_after_migration = false
  config.active_record.async_query_executor = :global_thread_pool

  # Required for signed cookies, encrypted credentials, etc.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")

  # Do not expose secrets in logs:
  # Never add DATABASE_URL here.
end
