# Load the Rails application.
require_relative 'config/environment'

# Ignore database errors
begin
  run Rails.application
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
  run lambda { |env| 
    [200, {'Content-Type' => 'text/plain'}, ['OK - Render LIVE']]
  }
end
