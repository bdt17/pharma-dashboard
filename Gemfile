source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.3"

gem "rails", "~> 8.1.1"
gem "bootsnap", require: false
gem "puma"
gem "pg", "~> 1.1"  # SINGLE pg declaration

# Auth + Security
gem "devise"
gem "pundit"
gem "jwt"

# GPS + Maps
gem "geocoder"
gem "chartkick"
gem "groupdate"

# Media
gem "image_processing"

# Rails 8.1 Solid Stack
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Compliance + Monitoring
gem "audited"
gem "sentry-rails"
gem "lograge"

group :development, :test do
  gem "sqlite3", "~> 2.0"

  gem "debug"
end

gem "playwright-ruby-client", "~> 1.57"

gem "wicked_pdf", "~> 2.8"
gem "wkhtmltopdf-binary", "~> 0.12.6"
