port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

preload_app!

# Rails 8 importmap - no workers needed for static dashboard
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
