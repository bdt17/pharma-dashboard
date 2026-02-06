source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "stripe", "~> 12.6"


gem "rails", "~> 8.1.1"
gem "bootsnap", require: false
gem "puma"
gem "rake", "13.2.1"
gem "pg", "~> 1.6"


# Auth (ONE devise only)
gem "devise"
gem "pundit"
gem "jwt"

# GPS + Maps
gem "geocoder"
gem "chartkick"
gem "groupdate"

# Media
gem "image_processing"

# PDF - Use wicked_pdf (production stable)

# Compliance + Monitoring
gem "audited"
gem "sentry-rails"
gem "lograge"

group :development, :test do
  gem "sqlite3", "~> 2.0"
  gem "debug"
end

# Testing
gem "playwright-ruby-client", "~> 1.57"
gem "rspec-rails", "~> 8.0"
gem "rspec-retry", "~> 0.6.2"
gem "factory_bot_rails", "~> 6.5"
gem "shoulda-matchers", "~> 7.0"
gem "capybara", "~> 3.40", group: :test
gem "selenium-webdriver", "~> 4.39", group: :test


gem 'solid_cable'
gem 'wkhtmltopdf-binary'
gem 'audited'
gem 'prawn'
gem 'prawn-table'
gem 'stripe-rails', require: 'stripe'
