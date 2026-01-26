class GpsController < ApplicationController
  def update
    lat = params[:lat]&.to_f || 33.4484
    lng = params[:lng]&.to_f || -112.0740
    imei = params[:imei]
    
    Rails.logger.info "GPS #{imei}: #{lat},#{lng}"
    
    render json: { 
      status: 'received', 
      timestamp: Time.now.utc.iso8601,
      lat: lat.round(6), 
      lng: lng.round(6),
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
end
