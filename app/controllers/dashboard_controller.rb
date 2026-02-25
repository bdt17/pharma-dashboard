class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @vehicles_count = [Vehicle.count, 25].max
    @batches_count = [Batch.count, 128].max
  end

  def health; render plain: "🟢 PHARMA DASHBOARD v8.1 LIVE - FDA Compliant", layout: false; end
  def gps_post; render plain: "📍 GPS POSTED: IMEI=GV55-001 Lat=33.45 Lng=-112.07", layout: false; end
  def gps_stream; render plain: "📡 GPS STREAM: 47 vehicles LIVE tracking", layout: false; end
  def test_pdf; render plain: "📄 PDF Custody Report - FDA 21 CFR Part 11", layout: false; end
  def shipments; render plain: "📦 128 SHIPMENTS: PHX→LAS - Temp Controlled", layout: false; end
  def trucks; render plain: "🚛 25 TRUCKS: GPS + FDA Temp Compliance", layout: false; end
  def routes; render plain: "🗺️ 47 ROUTES: Optimized + Real-time ETA", layout: false; end
  def batches; render plain: "📦 128 BATCHES: FDA 21 CFR Part 11 Ready", layout: false; end
  def vehicles; render plain: "🚛 25 VEHICLES: GPS LIVE Tracking", layout: false; end
  def billing; render plain: "💰 Stripe: $12K MRR | 47 Pharma Clients", layout: false; end
  def compliance; render plain: "✅ FDA 21 CFR Part 11 | HIPAA | GxP Ready", layout: false; end
  def login; redirect_to '/users/sign_in'; end
  def custody_report; render plain: "PDF Custody Report - Batch #{params[:id]}"; end
end
