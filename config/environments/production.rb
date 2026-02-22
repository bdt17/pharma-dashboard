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
