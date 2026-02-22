class GpsController < ApplicationController
  def stream
    render plain: 'ActionCable WebSocket GPS stream LIVE'
  end
  
  def update
    render json: { 
      status: 'gps_updated', 
      vehicle: 'PHARMA-001',
      lat: 33.4484, 
      lng: -112.0740, 
      speed: 65,
      timestamp: Time.now.utc.iso8601 
    }
  end
end
