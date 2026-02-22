class ApplicationController < ActionController::Base
  # No global auth - public Phase 8 endpoints
  protect_from_forgery prepend: true
  
  def root
  end
end

def signup
  render plain: "🚀 Phase 8 Enterprise - Contact sales@pharmatransport.com | $99/mo per vehicle"
end
