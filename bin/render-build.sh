#!/usr/bin/env bash
# Remove old assets
rm -rf public/assets
bundle install
bundle exec rails db:prepare
# Rails 8: use proper asset commands
bundle exec rails assets:precompile
