#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails db:migrate RAILS_ENV=production
# Rails 8.1 Propshaft - no assets:precompile needed
