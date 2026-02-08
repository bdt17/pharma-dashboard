class HealthController < ApplicationController
  def show
    render json: { 
      status: 'ok', 
      timestamp: Time.now.utc.iso8601,
      version: 'v8.1 Phase 8',
      mrr: '$990',
      vehicles: Vehicle.count,
      batches: Batch.count,
      uptime: 'LIVE'
    }
  end
end
