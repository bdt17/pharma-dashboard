#!/usr/bin/env bash
set -o errexit

bundle install
# Rails 8.1 Propshaft: NO assets:precompile needed
# Skip DB migrate - Render handles via env vars
echo "Build complete - Rails 8.1 ready"
