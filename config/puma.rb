# Render Rails 8.1.2 + WickedPDF Production
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

# CRITICAL: Load Rails application
rackup      DefaultRackup
require     "./config/environment" 

preload_app!

# Render logging
stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true

plugin :tmp_restart
