class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def root
    render layout: false  # Forces HTML template (no Rails layout)
  end
  
  def signup
    render plain: "🚀 Enterprise Trial: sales@pharmatransport.com | $99/mo"
  end
end

  def health
    render plain: "Pharma Transport Enterprise v9.2 - OK", status: 200
  end
