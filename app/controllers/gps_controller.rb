class GpsController < ApplicationController
  def update
    render json: {
      status: 'received',
      timestamp: Time.now.utc.iso8601,
      lat: (params[:lat] || 33.4484).to_f.round(6),
      lng: (params[:lng] || -112.0740).to_f.round(6),
      imei: params[:imei] || 'GV55-001',
      vehicles: 24,
      fda_compliant: true,
      thomas_it: 'Phoenix AZ Pharma Transport'
    }
  end
  
  def stream
    render json: {
      lat: 33.4484 + rand(-0.01..0.01),
      lng: -112.0740 + rand(-0.01..0.01),
      vehicle: 'GV55-001',
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
      vehicles: 24,
      uptime: Time.now.to_i - Rails.boot_time.to_i,
      thomas_it: 'pharma-dashboard phoenix az'
    }
  end
end
