Rails.application.configure do
  # Core production settings
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.force_ssl = true
  config.time_zone = 'Mountain Time (US & Canada)'
  config.eager_load = true
  
# Phase 14 LIVE - Solid features
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue

  # ActionCable CORS
  config.action_cable.allowed_request_origins = ['https://pharma-dashboard-beq2.onrender.com']

  # Render domains
  config.hosts << "pharma-dashboard-beq2.onrender.com"
  config.hosts << "*.onrender.com"
end
