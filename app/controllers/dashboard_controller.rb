class DashboardController < ApplicationController
  def index
    render plain: "PHARMA DASHBOARD LIVE\n127 Batches | 24 Vehicles | $12K\nPHX-001 Scottsdale ETA 8min\nPHX-002 Tempe ETA 12min\n\nPhase 14 PRODUCTION", layout: false
  end
end
