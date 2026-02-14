#!/usr/bin/env bash
set -e

# Rails 8.1 = rake assets:precompile
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rails db:migrate
