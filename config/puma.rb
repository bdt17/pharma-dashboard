# Render Rails 8.1.2 Production Puma
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

# Load Rails AFTER credentials
preload_app!

# Render logging
stdout_redirect '-', '-', true

plugin :tmp_restart
