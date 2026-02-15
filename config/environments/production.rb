Rails.application.configure do
  config.log_level = :info
  config.eager_load = false
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.force_ssl = false
  config.public_file_server.enabled = true
  config.i18n.fallbacks = true
  config.active_support.perform_deep_freeze = false
  config.assets.compile = true
end
