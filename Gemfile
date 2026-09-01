source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

gem "rails", "~> 8.1.3"
gem "puma", "~> 8.0"
gem "devise", "~> 5.0"  # SINGLE devise entry
# bcrypt is a devise dependency, so it's always installed -- but a transitive
# dep is not auto-required by Bundler. Devise loads it lazily on the first
# password check, which never happens on a session-cookie request, so
# TwoFactorAuthentication#generate_backup_codes! (BCrypt::Password) hit an
# uninitialized-constant NameError in production. Naming it here makes
# Bundler require it at boot.
gem "bcrypt", "~> 3.1"
gem "pundit", "~> 2.4"
gem "rack-attack", "~> 6.7"
gem "bootsnap", require: false
# importmap-rails needs an actual asset pipeline gem to serve the JS files
# it pins -- neither this nor sprockets-rails was ever installed, so every
# pinned/vendored JS asset 404'd and no Stimulus controller in this app has
# ever actually loaded in a browser. Propshaft is Rails 8's default pairing
# with importmap-rails (no Node build step needed).
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
# Every Tailwind utility class used across app/views (p-2, border, max-w-lg,
# text-2xl, etc.) has never actually rendered -- no Tailwind CSS was loaded
# anywhere, in any environment. package.json/Procfile.dev/app/assets/tailwind
# were leftover scaffolding from a setup that was started and abandoned; this
# gem was never actually in the Gemfile. Ruby-vendored Tailwind CLI, no Node
# build step needed, and it hooks into assets:precompile automatically.
gem "tailwindcss-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Background jobs. The ActiveJob adapter was the in-process :async pool,
# which drops every queued job on process restart -- fine for nothing that
# matters, but the temperature-excursion alert emails (ExcursionMonitor ->
# deliver_later) do matter. Solid Queue is Rails 8's default: a real,
# durable queue backed by Postgres (no Redis), with its tables living in
# the primary database here rather than a separate one. Runs inside Puma
# via the plugin in config/puma.rb -- right for this app's volume; split
# it into a dedicated worker process later if that changes.
# config/queue.yml and config/recurring.yml were already in the repo,
# waiting for this.
gem "solid_queue", "~> 1.4"

# PostgreSQL adapter — used in every environment (development, test, production).
gem "pg", "~> 1.5"

# Chain-of-custody PDF generation. app/services/pdf_chain_of_custody_generator.rb
# already called Prawn::Document -- it was just never added to the Gemfile, so
# that service has never actually run. Pure-Ruby, no external binary needed
# (unlike wkhtmltopdf, which render.yaml referenced but nothing ever used).
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"

# Billing. Used for webhook signature verification (Stripe::Webhook.construct_event)
# so the webhook endpoint is real and safe to point Stripe at whenever real API
# keys are configured -- no live checkout/charge code ships in this phase, since
# that needs a real Stripe account this repo doesn't have (see the Phase 5 PR).
gem "stripe", "~> 19.5"

# Two-factor authentication (TOTP). rotp does the RFC 6238 verify/provision;
# rqrcode renders the enrollment QR as inline SVG. Both are pure Ruby with no
# system dependencies (no ImageMagick / libqrencode). Devise itself has no
# second-factor support, and devise-two-factor's current releases require
# ActiveRecord encryption, which this app has no credentials/master.key for --
# so the TOTP layer here is built directly on rotp instead. See
# app/models/concerns/two_factor_authenticatable.rb.
gem "rotp", "~> 6.3"
gem "rqrcode", "~> 3.2"

# SMS temperature-excursion alerts (Pro/Compliance tiers). Twilio's REST
# client -- used only by SmsSender, which is a no-op until
# TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN / TWILIO_MESSAGING_FROM are set as
# env vars, the same "safe until configured" pattern as Stripe and SMTP
# here. No live credentials ship in this repo.
gem "twilio-ruby", "~> 7.4"

group :development, :test do
  # Static analysis, linting, and dependency-vulnerability scanning used by CI
  # (.github/workflows/ci.yml). These match what that workflow actually invokes.
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "bundler-audit", require: false
end

group :test do
  # Lets tests actually extract and assert on generated PDF text, instead of
  # just checking "did some bytes come back" -- the whole point of Phase 3
  # is proving real data replaced hardcoded stub content.
  gem "pdf-reader", "~> 2.12"

  # Browser system tests (test/system/*). Headless Chrome via Selenium
  # Manager -- no separate chromedriver to install. Chrome itself is
  # pre-installed on the GitHub ubuntu runners.
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.27"

  # minitest 6 extracted Minitest::Mock / Object#stub into this separate
  # gem. Needed to stub Stripe API calls in tests without a real Stripe
  # account or network access (see StripeBillingTest).
  gem "minitest-mock", "~> 5.27", require: "minitest/mock"
end
