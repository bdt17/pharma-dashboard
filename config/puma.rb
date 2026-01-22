port        ENV.fetch("PORT") { 3000 }
environment "production"
threads     5, 5
workers     2

# DISABLE preload_app! for Render debugging
# preload_app!
