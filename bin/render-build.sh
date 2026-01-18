#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -e

# Install Ruby gems
bundle install

# Precompile assets (if using asset pipeline)
# bin/rails assets:precompile

# Install Node.js dependencies (if using Webpacker/jsbundling)
yarn install --frozen-lockfile
