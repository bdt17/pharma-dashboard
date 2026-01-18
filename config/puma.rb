# Render Rails 8.1.2 + WickedPDF Production
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

# FIXED: String quotes required
rackup      "config.ru"
preload_app!

# Render logging
stdout_redirect '-', '-', true

plugin :tmp_restart
