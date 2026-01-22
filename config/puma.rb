port        ENV.fetch("PORT") { 3000 }
host        ENV.fetch("HOST") { "0.0.0.0" }
environment ENV.fetch("RAILS_ENV") { "production" }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count
preload_app!
