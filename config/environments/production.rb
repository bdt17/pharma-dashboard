Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  
  # Logs
  config.log_level = :info
  
  # Don't show full error stacktraces
  config.active_support.deprecation = :notify
  
  # Force all access to assets go to through asset pipeline
  
  # Mailer (disable for now)
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
end
