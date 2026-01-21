port        ENV.fetch("PORT") { 3000 }
host        ENV.fetch("HOST") { "0.0.0.0" }
environment ENV.fetch("RAILS_ENV") { "production" }
threads 2, 6
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
preload_app!
