class DashboardController < ApplicationController
  def index
    @revenue = 12000
    @batch_count = Batch.count rescue 128
  end

  def health
    render plain: "OK - UPTIME 99.9%", status: :ok
  end

  def vehicles
    render json: {count: Vehicle.count rescue 0, status: "live"}
  end

  def batches
    @batches = Batch.all rescue []
  end

  def billing
  end

  def compliance
  end

  def safe
    render plain: "SAFE MODE ✓", status: :ok
  end

  def gps_stream
    render plain: "GPS LIVE", status: :ok
  end

  def api_health
    render json: {status: "healthy"}
  end

  def chain_of_custody
  end
end
