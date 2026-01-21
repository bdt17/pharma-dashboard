# Load Rails first
require_relative "config/environment"

# Use correct PORT for Render
port        ENV.fetch("PORT") { 3000 }
host        ENV.fetch("HOST") { "0.0.0.0" }

# PRODUCTION environment only
environment ENV.fetch("RAILS_ENV") { "production" }

# Thread pool for concurrent requests
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Use standard Rails logger
stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true

# Never pre-load app (Render requirement)
preload_app!

# Allow puma restart in-place
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
