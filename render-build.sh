#!/usr/bin/env bash
# PHARMA ENTERPRISE RENDER BUILD v15.0.0
set -e

# Rails 8 = NO assets:precompile (css/js in app/assets → auto)
echo "✅ Rails 8.1.2 - Assets auto-served (no precompile)"

# Install deps
bundle install

# Run migrations
bundle exec rails db:migrate

# Health check
bundle exec rails runner "puts 'PHARMA ENTERPRISE LIVE ✓'"
