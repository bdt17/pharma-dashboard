class GpsController < ApplicationController
  def update
    render json: {
      status: 'received',
      timestamp: Time.now.utc.iso8601,
      lat: (params[:lat] || 33.4484).to_f.round(6),
      lng: (params[:lng] || -112.0740).to_f.round(6),
      imei: params[:imei] || 'GV55-001',
      vehicles: 24,
      fda_compliant: true
    }
  end

  def stream
    render json: {
      lat: 33.4484 + rand(-0.01..0.01),
      lng: -112.0740 + rand(-0.01..0.01),
      vehicles: 24,
      active_batches: 127
    }
  end

  def health
    render json: {status: 'ok', rails: '8.1.1', gps: 'ready', vehicles: 24}
  end
end
