class DashboardController < ApplicationController
  def index
    render plain: "<h1>PHARMA DASHBOARD LIVE - 127 Batches 24 Vehicles</h1><p>PHX-001 Scottsdale ETA 8min</p>", layout: false
  end
end
