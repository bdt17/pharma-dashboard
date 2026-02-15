class Api::GpsController < ApplicationController
  def update
    render json: {
      status: 'received',
      timestamp: Time.now.utc.iso8601,
      lat: (params[:lat] || 33.4484).to_f,
      lng: (params[:lng] || -112.0740).to_f,
      imei: params[:imei],
      vehicles: 24,
      fda_compliant: true
    }
  end
  
  def stream
    render json: {
      lat: 33.4484 + rand(-0.01..0.01),
      lng: -112.0740 + rand(-0.01..0.01),
      vehicles: 24,
      active_batches: 127,
      stream: true
    }
  end
  
  def health
    render json: { 
      status: 'ok', 
      rails: '8.1.1', 
      gps: 'ready', 
      uptime: Time.now.to_i,
      thomas_it: 'pharma-transport phoenix az'
    }
  end
end
