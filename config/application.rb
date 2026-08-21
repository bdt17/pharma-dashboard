require_relative "boot"

require "rails/all"
require "devise"
require "devise/orm/active_record"

Bundler.require(*Rails.groups)

module PharmaDashboard
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = false

    config.generators do |g|
      g.orm :active_record
    end
  end
end
