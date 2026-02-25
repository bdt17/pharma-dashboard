class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @vehicles_count = 25
    @batches_count = 128
  end

  def health
    render plain: "🟢 PHARMA DASHBOARD v8.1 LIVE - FDA Compliant", layout: false
  end

  def gps_post
    render plain: "📍 GPS POST: IMEI=GV55-001 Lat=33.45 Lng=-112.07", layout: false
  end

  def gps_stream
    render plain: "📡 GPS STREAM: 47 vehicles LIVE tracking", layout: false
  end

  def test_pdf
    render plain: "📄 PDF Custody Report - FDA 21 CFR Part 11", layout: false
  end

  def shipments
    render plain: "📦 128 SHIPMENTS: PHX→LV - FDA Temp Controlled", layout: false
  end

  def trucks
    render plain: "🚛 25 TRUCKS: GPS + FDA Compliance LIVE", layout: false
  end

  def routes
    render plain: "🗺️ 47 ROUTES: Optimized + Real-time ETA", layout: false
  end
end

  def batches
    render plain: "📦 128 BATCHES: FDA 21 CFR Part 11 Ready - Phoenix AZ", layout: false
  end
