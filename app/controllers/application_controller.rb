class ApplicationController < ActionController::Base
  # Skip global auth for test endpoints
  skip_before_action :authenticate_user!, 
    only: [:health, :api_health, :vehicles, :batches, :billing, :gps_update, :gps_stream]
    
  # Devise Turbo fix  
  protect_from_forgery prepend: true
end
