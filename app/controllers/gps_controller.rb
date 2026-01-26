class GpsController < ApplicationController
  def update
    render json: { 
      status: 'received', 
      lat: params[:lat] || 33.4484,
      lng: params[:lng] || -112.0740,
      imei: params[:imei],
      vehicles: 24,
      timestamp: Time.now.utc.iso8601
    }
  end
  
  def stream
    render json: { 
      lat: 33.4484, 
      lng: -112.0740,
      vehicles: 24,
      active: 127
    }
  end
  
  def health
    render json: { status: 'ok', rails: '8.1.1', gps: 'ready' }
  end
end
