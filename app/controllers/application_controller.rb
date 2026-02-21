class ApplicationController < ActionController::Base
  # DISABLE GLOBAL AUTH - Enterprise endpoints first
  skip_before_action :authenticate_user!
  
  # Devise Turbo compatibility
  protect_from_forgery prepend: true
  
  # Re-enable auth only for user routes later
end
