# RAILS 8 + DEVISE 4.9.4 PRODUCTION FIX
require 'devise'
Dir[Rails.root.join('app/models/**/*.rb')].each { |f| require_dependency f }

# Force Devise mappings AFTER models loaded
Rails.application.config.to_prepare do
  Devise.mappings.clear
  Rails.application.reload_routes!
end
