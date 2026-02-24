class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def root
    render layout: false  # Forces HTML template (no Rails layout)
  end
  
  def signup
    render plain: "🚀 Enterprise Trial: sales@pharmatransport.com | $99/mo"
  end
end

  end

  end


protected

end

  end

  end
  
  end

  end

  end

  end

  end

  # Health endpoints - SINGLE COPY ONLY
  end

  # Root dashboard
  end

  # SINGLE Health endpoint
  def health
    render plain: "Pharma Transport Enterprise v9.2 - OK", status: 200
  end

  # SINGLE Root dashboard  
  def index
    render plain: "Pharma Transport Dashboard v9.2 - LIVE", status: 200
  end
def health; render plain: "OK", status: 200; end
