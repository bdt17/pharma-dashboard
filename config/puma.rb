# Rails 8.1.2 + Render Production Puma Config
require "./config/environment"  # Load Rails

port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

rackup      DefaultRackup         # REQUIRED: Load config.ru
threads     1, 5

preload_app!

# Render logging
stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true
