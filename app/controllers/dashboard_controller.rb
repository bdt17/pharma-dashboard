class DashboardController < ApplicationController
  def index
    render plain: "PHARMA DASHBOARD LIVE - Truck 001", status: :ok
  end

  def health
    render plain: "OK", status: :ok
  end

  def api_health
    render json: {status: "ok", trucks: 1, batches: 1}
  end

  def vehicles
    render plain: "Truck 001 ACTIVE", status: :ok
  end

  def batches
    render plain: "LOT-PHARMA-20260217", status: :ok
  end

  def billing
    render plain: "$99/mo", status: :ok
  end
end
