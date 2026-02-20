class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: [:health, :api_health]

  def index
    @vehicles = Vehicle.all rescue []
    @batches = Batch.all rescue []
  end

  def health
    render plain: "Thomas IT Pharma LIVE", status: :ok
  end

  def api_health
    render json: { 
      status: "ok", 
      vehicles: Vehicle.count rescue 0,
      batches: Batch.count rescue 0
    }
  end

  def vehicles; end
  def batches; end
  def compliance; end
  def billing
    render plain: "Phase 8 $99/mo ready"
  end
end

