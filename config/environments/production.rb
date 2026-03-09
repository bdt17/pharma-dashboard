Rails.application.configure do
  # URL options (Line 2-4 fixed)
  config.action_controller.default_url_options = {
    host: ENV['APP_HOST'] || 'dashboard.pharmatransport.org',
    protocol: :https
  }

  # Standard production settings
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Mailer (Render.com SMTP)
  config.action_mailer.default_url_options = { 
    host: ENV['APP_HOST'] || 'dashboard.pharmatransport.org',
    protocol: :https
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_SERVER'] || 'smtp.render.com',
    port:                 ENV['SMTP_PORT'] || 587,
    domain:               ENV['SMTP_DOMAIN'] || 'pharmatransport.org',
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       :login,
    enable_starttls_auto: true
  }

  # Security
  config.force_ssl = true
  config.log_level = :info

  # Assets (Rails 8 + Propshaft)
  config.assets.compile = false
  config.assets.digest = true

  # Database (Render PostgreSQL)
  config.active_record.async_query_executor = :global_thread_pool

  # Stripe + GPS config
  config.x.stripe.public_key = ENV['STRIPE_PUBLIC_KEY']
  config.x.stripe.secret_key = ENV['STRIPE_SECRET_KEY']

  # Render.com optimizations
  config.cache_store = :memory_store, { size: 64.megabytes }
end
