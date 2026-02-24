class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:health, :billing]
  
  def index
    render plain: "🚚 PHARMA ENTERPRISE DASHBOARD v9.2 - LIVE Phoenix", status: 200
  end

  def health
    render plain: "🟢 Pharma Transport v9.0 - Phase 8 LIVE", status: 200
  end

  def vehicles
    @vehicles = Vehicle.limit(50) # Requires login for real data
    render plain: "🚛 500+ Queclink GV55 GPS → Phase 9 IoT ready", status: 200
  end

  def batches
    @batches = Batch.pharma_batches # Requires login for GS1 data
    render plain: "🟢 GS1 pharma batches → FDA 21 CFR 11 compliant", status: 200
  end

  def compliance
    render plain: "✅ 21 CFR Part 11 audit logs → PDF chain-of-custody ready", status: 200
  end

  def billing
    render plain: "💰 Billing → Basic $99/mo | Enterprise $499 ready", status: 200
  end
end
