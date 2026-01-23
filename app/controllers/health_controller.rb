class HealthController < ApplicationController
  def show
    render json: { 
      status: 'live', 
      timestamp: Time.current,
      batches: 127, 
      vehicles: 24,
      gps_active: true
    }
  end
end
