Rails.application.configure do
  config.hosts.clear
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: 'pharma-dashboard-8jhe.onrender.com' }

  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.force_ssl = true
  config.time_zone = 'Mountain Time (US & Canada)'
  
  # Phase 14 LIVE
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.action_cable.allowed_request_origins = ['https://pharma-dashboard-8jhe.onrender.com']
end
