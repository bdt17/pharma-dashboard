class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def root
    render plain: "🚚 Pharma Transport Dashboard - Phase 8 Enterprise LIVE"
  end
  
  def signup
    render plain: "Enterprise Sign-up: sales@pharmatransport.com | $99/mo"
  end
end
