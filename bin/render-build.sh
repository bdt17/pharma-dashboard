#!/usr/bin/env bash
set -e

# Rails 8 importmap - no assets to precompile
echo "Rails 8 importmap app — no assets to precompile"

# Skip migrations if no DB configured
bundle exec rails db:migrate || echo "No database migrations needed"
