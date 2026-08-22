source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

gem "rails", "~> 8.1.3"
gem "puma", "~> 7.2"
gem "devise", "~> 5.0"  # SINGLE devise entry
gem "pundit", "~> 2.4"
gem "bootsnap", require: false
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", "~> 5.0"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "image_processing", "~> 1.2"

# PostgreSQL adapter — used in every environment (development, test, production).
gem "pg", "~> 1.5"

group :development, :test do
  # Static analysis, linting, and dependency-vulnerability scanning used by CI
  # (.github/workflows/ci.yml). These match what that workflow actually invokes.
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "bundler-audit", require: false
end
