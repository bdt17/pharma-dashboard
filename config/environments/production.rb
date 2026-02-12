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
  #  config.cache_store = :solid_cache_store
  # config.active_job.queue_adapter = :solid_queue
  # Standard production cache
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :async

  config.eager_load = true  # ← ADD THIS LINE (fixes warning)


  # ActionCable CORS
  config.action_cable.allowed_request_origins = ['https://pharma-dashboard-beq2.onrender.com']

  # Render domains
  config.hosts << "pharma-dashboard-beq2.onrender.com"
  config.hosts << "*.onrender.com"
  # Disable Solid Cable (single DB production)
 config.action_cable.disable_request_forgery_protection = true

# Use single DATABASE_URL for everything
end
config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
config.assets.compile = true
