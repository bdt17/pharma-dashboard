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

    # Nothing in this app uses ActiveStorage attachments/variants (no
    # has_one_attached / .variant( anywhere) -- the image_processing gem
    # was dead weight and got removed. Say so explicitly rather than
    # booting with a recurring "please add image_processing" warning.
    config.active_storage.variant_processor = :disabled
  end
end
