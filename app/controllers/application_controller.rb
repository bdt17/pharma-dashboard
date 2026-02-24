class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true

  def health
    render plain: "Pharma Transport v9.0 - Phase 8 LIVE", status: 200
  end
end
