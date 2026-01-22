port        ENV.fetch("PORT")
environment "production"
threads     1, 1

# SINGLE MODE - no cluster warnings
workers 0
silence_single_worker_warning
