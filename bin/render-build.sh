#!/usr/bin/env bash
bundle lock --add-platform x86_64-linux
bundle install
rails assets:precompile
rails db:prepare
