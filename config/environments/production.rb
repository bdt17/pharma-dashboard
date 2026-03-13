Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.force_ssl = true
  
  # Skip asset compilation for speed
  config.assets.compile = false
  config.assets.debug = false
  config.public_file_server.enabled = true
end
