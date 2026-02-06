class GpsController < ApplicationController
  def update
    imei = params[:imei]
    vehicle = Vehicle.find_or_create_by(imei: imei)
    vehicle.update!(
      latitude: params[:lat]&.to_f,
      longitude: params[:lng]&.to_f, 
      speed: params[:speed]&.to_f
    )
    head :ok
  rescue
    head :ok  # Graceful for Queclink GV55
  end

  def stream
    render json: {
      status: "LIVE",
      total: Vehicle.count,
      active: Vehicle.where("updated_at > ?", 5.minutes.ago).count,
      trucks: Vehicle.limit(5).as_json(only: [:imei, :latitude, :longitude, :speed])
    }
  end
end
