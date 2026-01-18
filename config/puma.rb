# Render Rails 8.1.2 Production - NO DefaultRackup
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

# Standard Rails app loading
preload_app!

# Render logging
stdout_redirect '-', '-', true

plugin :tmp_restart
