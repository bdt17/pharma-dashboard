class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:health]

  def index
    @vehicles = Vehicle.limit(10)
    @batches = Batch.where(active: true).limit(10)
  end

  def health
    render plain: "OK", status: :ok
  end

  def api_health
    render json: {
      status: "ok",
      rails: Rails.version,
      vehicles: Vehicle.count,
      batches: Batch.count,
      ts: Time.now.utc.iso8601
    }
  end

  def vehicles
    @vehicles = Vehicle.all
  end

  def batches
    @batches = Batch.all
  end

  def compliance
    @batches = Batch.where.not(lot_number: nil)
  end

  def billing
    render plain: "Stripe $99/mo per vehicle"
  end
end
