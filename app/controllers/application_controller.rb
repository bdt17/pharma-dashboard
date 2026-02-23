class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def root
    render 'root'  # Uses app/views/application/root.html.erb
  end
  
  def signup
    render plain: "Enterprise Trial: sales@pharmatransport.com | $99/mo per vehicle"
  end
end
