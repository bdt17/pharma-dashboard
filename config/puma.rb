workers 0
threads 1, 1
environment "production"
port ENV.fetch("PORT") { 10000 }

# Run the Solid Queue worker as a child of Puma instead of a separate
# process/dyno -- right for this app's job volume (a handful of alert
# emails). If throughput ever needs its own box, drop this line and run
# `bin/jobs` (or `bundle exec rake solid_queue:start`) as a dedicated
# service. Skipped in test, where Capybara boots its own Puma without
# this config and jobs run inline via the :test adapter.
plugin :solid_queue unless ENV["RAILS_ENV"] == "test"
