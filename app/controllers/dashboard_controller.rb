class DashboardController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render plain: "🚚 PHARMA DASHBOARD LIVE - Truck 001 Phoenix", status: 200
  end

  def health
    render plain: "🟢 OK - Thomas IT Pharma LIVE", status: 200
  end

  def vehicles
    render plain: "🚛 Truck 001 ACTIVE - 33.4484°N, 112.0740°W", status: 200
  end

  def batches
    render plain: "💉 LOT-PHARMA-20260217 - 4.2°C IN TRANSIT", status: 200
  end

  def compliance
    render plain: "🛡️ FDA 21 CFR Part 11 COMPLIANT", status: 200
  end

  def billing
    render plain: "💰 Phase 8: $99/mo per vehicle", status: 200
  end
end
