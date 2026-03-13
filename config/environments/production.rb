Rails.application.configure do
  # Phase 10 - Minimal production config (no assets needed)
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  
  # No asset pipeline needed for Phase 10 stubs
  config.public_file_server.enabled = true
  
  # No logging noise
  config.log_level = :warn
  
  # Essential security
  config.force_ssl = false  # Render handles HTTPS
  
  # No DB needed
  config.active_record.async_query_executor = :global_thread_pool
end
