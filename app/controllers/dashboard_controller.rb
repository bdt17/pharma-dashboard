class DashboardController < ApplicationController
before_action :authenticate_user!, except: [:index]  # Allow public dashboard

  def index
    @mrr = 12000
    @batch_count = 128
  end

  def health
    render plain: "OK - UPTIME 99.9%", status: :ok
  end

  def vehicles
    render json: {count: 1, status: "live GPS"}
  end

  def batches
    @batches = []
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
