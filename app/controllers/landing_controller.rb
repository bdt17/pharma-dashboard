class LandingController < ApplicationController
  def index
    render html: "<h1>Pharma Transport Dashboard - Phoenix AZ</h1><p>LIVE ✓</p>".html_safe
  end
end
