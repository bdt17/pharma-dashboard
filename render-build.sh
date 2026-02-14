#!/usr/bin/env bash
set -e

# Rails 8.1 = "rails" NOT "rake"
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
