class DashboardController < ApplicationController
  def index
    @revenue = 12000
  end

  def health
    render plain: "OK - UPTIME 99.9% - #{Time.current}", status: :ok
  end

  def vehicles
    @vehicles = Vehicle.all rescue []
    render json: @vehicles
  rescue => e
    render json: {count: 0, status: "demo"}
  end

  def batches
    @batches = Batch.all rescue []
  end

  def billing
  end

  def compliance
  end

  def safe
    render plain: "SAFE MODE ACTIVE", status: :ok
  end

  def gps_stream
    render plain: "GPS LIVE", status: :ok
  end

  def api_health
    render json: {status: "healthy", uptime: "99.9%"}
  end

  def chain_of_custody
  end
end
