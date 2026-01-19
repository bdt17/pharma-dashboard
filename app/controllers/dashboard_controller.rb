class DashboardController < ApplicationController
  layout nil
  
  def index
    render file: "public/dashboard.html", layout: false, content_type: "text/html"
  end
end
