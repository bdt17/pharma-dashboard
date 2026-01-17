require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module PharmaDashboard
  class Application < Rails::Application
    config.load_defaults 8.1
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en]
    config.i18n.fallbacks = [:en]
    config.api_only = false
  end
end


