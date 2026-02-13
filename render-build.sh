#!/usr/bin/env bash
set -e
bundle install
bundle exec rails db:migrate
bundle exec rails runner "puts 'PHARMA ENTERPRISE LIVE ✓'"
