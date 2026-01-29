class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery prepend: false, except: [:update]

  def update
    imei = params[:imei]&.strip
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f

    # Log incoming data
    Rails.logger.info "GPS: imei=#{imei} lat=#{lat} lng=#{lng}"

    # Simple JSON response - NO DATABASE
    render json: { 
      status: 'received', 
      imei: imei, 
      lat: lat, 
      lng: lng,
      timestamp: Time.current.iso8601 
    }, status: :ok
  end

  def stream
    render plain: "GPS Stream LIVE", status: :ok
  end

  def health
    render json: { status: 'ok', timestamp: Time.current, vehicles: 24 }
  end
end
