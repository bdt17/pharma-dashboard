#!/usr/bin/env bash
rm -rf public/assets tmp/cache/assets
bundle lock --add-platform x86_64-linux
bundle install
yarn install --frozen-lockfile
bundle exec rails javascript:build
bundle exec rails css:build
bundle exec rails db:prepare
