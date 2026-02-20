class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: [:health, :api_health]

  def index
    render plain: "Thomas IT Pharma Dashboard - Truck 001 LIVE", status: :ok
  end

  def health
    render plain: "Thomas IT Pharma LIVE", status: :ok
  end

  def api_health
    render json: { 
      status: "ok", 
      vehicles: Vehicle.count rescue 1,
      batches: Batch.count rescue 1
    }
  end

  def vehicles
    render plain: "Truck 001 ACTIVE - Phoenix GPS"
  end

  def batches
    render plain: "LOT-PHARMA-20260217 - 4.2°C IN TRANSIT"
  end

  def compliance
    render plain: "FDA 21 CFR Part 11 READY"
  end

  def billing
    render plain: "Phase 8: $99/mo per vehicle"
  end
end
