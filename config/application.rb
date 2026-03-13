require_relative "boot"

require "rails"
Bundler.require(*Rails.groups)

module PharmaDashboard
  class Application < Rails::Application
    config.load_defaults 7.0
    config.api_only = false
    
    # DISABLE ZEITWERK EAGER LOADING
    config.autoloader = :classic
  end
end
