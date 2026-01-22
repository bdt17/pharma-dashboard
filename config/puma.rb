workers 0
threads 1, 1
environment 'production'
port ENV.fetch("PORT") { 10000 }
