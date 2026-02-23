class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def root
    render file: "#{Rails.root}/app/views/application/root.html.erb", layout: false
  end
  
  def signup
    render plain: "🚀 Enterprise Trial: sales@pharmatransport.com | $99/mo"
  end
end
