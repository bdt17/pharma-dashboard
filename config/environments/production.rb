Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.log_level = :info
end

# Disable eager loading causing crashes
config.eager_load = false
config.cache_classes = true

# Disable asset pipeline
config.assets.compile = false
config.assets.debug = false
