class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token # GPS devices = no CSRF

  def update
    imei = params[:imei]
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f

    unless imei && lat && lng
      return head :unprocessable_entity 
    end

    # Update/Create vehicle location
    vehicle = Vehicle.find_or_initialize_by(imei: imei)
    vehicle.update(lat: lat, lng: lng, last_ping: Time.current)
    vehicle.save!

    # Real-time broadcast (ActionCable)
    ActionCable.server.broadcast 'gps_channel', {
      imei: imei,
      lat: lat,
      lng: lng,
      timestamp: Time.current.to_i
    }

    head :ok
  rescue => e
    Rails.logger.error "GPS Update Error: #{e.message}"
    head :unprocessable_entity
  end

  def stream
    render plain: "GPS Stream LIVE", status: :ok
  end

  def health
    render json: { status: 'ok', timestamp: Time.current, vehicles: 24 }
  end
end
