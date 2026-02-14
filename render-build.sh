#!/usr/bin/env bash
set -e

# Rails 8.1 inline CSS = NO precompile needed
bundle exec rails db:migrate
