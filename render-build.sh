#!/bin/bash
set -e

echo "==> Installing gems..."
bundle install --without development test

echo "==> Migrating database..."
bundle exec rails db:migrate

echo "==> Seeding database..."
bundle exec rails db:seed

echo "==> Build complete! Propshaft serves CSS directly."
