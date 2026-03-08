Rails.application.configure do
  config.log_level = :info
  config.eager_load = false
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.force_ssl = false
  config.public_file_server.enabled = true
  config.i18n.fallbacks = true
  config.active_support.perform_deep_freeze = false
end

# Silence Stripe production warning
Rails.application.config.stripe.secret_key = "sk_test_dummy_key"
Rails.application.config.stripe.secret_key = "sk_test_dummy"
Rails.application.config.stripe.secret_key = "sk_test_dummy"

# Enterprise pharma subdomain
config.action_controller.default_url_options = { 
  host: 'pharma.thomasinformationtechnology.com', 
  protocol: 'https' 
}
config.action_mailer.default_url_options = { 
  host: 'pharma.thomasinformationtechnology.com', 
  protocol: 'https' 
}
config.hosts << "pharmatransport.org"
config.hosts << "dashboard.pharmatransport.org"
config.hosts << "api.pharmatransport.org"
