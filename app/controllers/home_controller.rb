class HomeController < ApplicationController
  def index
    @title = "PHARMA TRANSPORT DASHBOARD"
    render layout: "application"
  end
  
  def vehicles
    render plain: "🚛 VEHICLES PAGE LIVE - Fleet Management", layout: "application"
  end
  
  def gps
    render plain: "🛰️ GPS TRACKING LIVE - Real-time Locations", layout: "application"
  end
end
