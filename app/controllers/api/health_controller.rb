class Api::HealthController < ApplicationController
  def index
    render json: { 
      status: 'OK', 
      timestamp: Time.now.utc,
      batches: Batch.count,
      vehicles: Vehicle.count,
      uptime: 'LIVE'
    }
  end
end
