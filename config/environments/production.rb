Rails.application.configure do
  # Secret key required for production
  config.secret_key_base = ENV['SECRET_KEY_BASE'] || 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6'
  
  # Production settings
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.force_ssl = false  # Render handles SSL
  
  # Static files for Render
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }
  
  # Logging
  config.log_level = :info
  
  # Don't generate system test files
  config.active_support.test_order = :random
end
