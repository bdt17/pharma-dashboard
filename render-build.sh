#!/bin/bash
set -e

echo "==> Installing gems..."
bundle config set without 'development test' --local
bundle install

echo "==> Migrating database..."
bundle exec rails db:migrate

echo "==> Seeding database (if exists)..."
bundle exec rails db:seed || echo "No seed data"

echo "==> Build complete! Rails 8.1 + Propshaft ready 🚀"
