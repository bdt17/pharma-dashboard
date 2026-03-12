class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Health check endpoint - fixes 404 errors
  def health
    render plain: "OK", status: :ok
  end
end
