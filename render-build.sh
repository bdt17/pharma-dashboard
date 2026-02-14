#!/usr/bin/env bash
set -e

bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
