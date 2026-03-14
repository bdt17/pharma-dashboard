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
  config.assets.debug = true

  # LOGGER FIX (CRITICAL)
  config.logger = ActiveSupport::Logger.new('log/development.log')
  config.log_level = :debug

  # EMAIL
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
end
