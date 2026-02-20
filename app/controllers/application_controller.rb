class ApplicationController < ActionController::Base
  # DISABLE GLOBAL AUTH FOR ENTERPRISE TEST ENDPOINTS
  skip_before_action :authenticate_user!
  
  protect_from_forgery prepend: true
end
