Devise.setup do |config|
  config.secret_key = Rails.application.secret_key_base
end

# RAILS 8 FIX: Ensure Devise modules available before routes
Devise.setup
