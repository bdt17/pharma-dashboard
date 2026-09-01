Rails.application.configure do
  # VERBOSITY/DEBUGGING
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :debugger
  config.active_support.deprecation = :log
  config.active_record.migration_error = :plain
  config.active_record.verbose_query_logs = true

  # LOGGER FIX (CRITICAL)

  # EMAIL
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  # No local mail catcher (letter_opener, mailcatcher, etc.) is set up in
  # this app -- an unconfigured delivery_method defaults to :smtp with no
  # smtp_settings, which raises ECONNREFUSED trying to reach localhost:25
  # the instant anything sends mail (password reset, account unlock, and
  # now signup confirmation -- see Users::RegistrationsController). :test
  # accepts the send without actually delivering anywhere, so those flows
  # work locally without crashing; there's just nowhere to see the email
  # body short of `ActionMailer::Base.deliveries` in a console.
  config.action_mailer.delivery_method = :test
  config.action_mailer.raise_delivery_errors = false

  # Match production: jobs go through Solid Queue, run by the in-Puma
  # worker (`plugin :solid_queue` in config/puma.rb) when the app is
  # started with `bin/dev` / `bin/rails server`. Run `bin/rails db:prepare`
  # once to create its tables. The test environment keeps the :test
  # adapter (set by rails/test_help).
  config.active_job.queue_adapter = :solid_queue
end
