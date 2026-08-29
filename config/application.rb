require_relative "boot"

require "rails/all"
require "devise"
require "devise/orm/active_record"

Bundler.require(*Rails.groups)

# Rack middleware, so it lives in lib/ and is required up front: it is added
# to the stack while the application class body evaluates, before autoload.
require_relative "../lib/dashboard_subdomain_redirect"

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

    # 301 dashboard.<domain> -> the canonical host. See the middleware file.
    config.middleware.use DashboardSubdomainRedirect

    # ActiveRecord Encryption for User#otp_secret, Vehicle#api_token, and
    # anything else marked `encrypts` later. This app keeps no Rails
    # credentials file, so the keys come from env vars in real environments
    # and from fixed, non-secret values in development/test -- nothing
    # sensitive is stored locally and CI must run without secrets. Set here,
    # not in config/initializers/, because the framework consumes this config
    # before app initializers run.
    #
    # `support_unencrypted_data` is off: every encrypted column
    # (User#otp_secret, Vehicle#api_token) has been confirmed to hold no
    # legacy plaintext rows in production -- the backfill tasks
    # (`two_factor:encrypt_secrets`, `vehicles:encrypt_api_tokens`) have run
    # and were verified. A plaintext value in one of these columns now raises
    # a decryption error instead of being read silently. Anything marked
    # `encrypts` from here on is encrypted-only by construction; run its
    # backfill (if the column already had data) with this briefly flipped
    # back to true, then flip it off again.
    config.active_record.encryption.support_unencrypted_data = false
    if Rails.env.local?
      config.active_record.encryption.primary_key = "development-and-test-only-not-a-real-key-primary"
      config.active_record.encryption.deterministic_key = "development-and-test-only-not-a-real-key-deterministic"
      config.active_record.encryption.key_derivation_salt = "development-and-test-only-not-a-real-key-derivation-salt"
    else
      config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY")
      config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY")
      config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT")
    end
  end
end
