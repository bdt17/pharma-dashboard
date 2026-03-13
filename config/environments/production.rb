Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  
  # Skip assets
  config.assets.compile = false
  config.public_file_server.enabled = true
end
