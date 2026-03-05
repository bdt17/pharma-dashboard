class Api::HealthController < ApplicationController
  def index
    render json: {
      status: 'OK',
      timestamp: Time.now.utc.iso8601,
      batches: Batch.count,
      vehicles: Vehicle.where(status: 'online').count,
      version: 'v8.1'
    }
  end
end
