Rails.application.configure do
  # Core settings
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  
  # Static files
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }
  
  # Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV['APP_HOST'] || 'localhost:3000' }
  
  # Logger
  config.log_level = :info
  config.log_tags = [ :request_id ]
  
  # i18n
  config.i18n.fallbacks = true
  
  # Deprecation
  config.active_support.deprecation = :notify
  
  # Force SSL
  config.force_ssl = false
  
  # Timezone
  config.time_zone = 'Mountain Time (US & Canada)'
end
