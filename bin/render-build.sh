#!/usr/bin/env bash
bundle install
yarn install --production || true
bundle exec rails db:prepare
