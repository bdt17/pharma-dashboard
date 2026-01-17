#!/usr/bin/env bash
bundle check || bundle install
SECRET_KEY_BASE=1 bundle exec rails assets:precompile
bundle exec rails db:migrate
