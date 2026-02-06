class GpsController < ApplicationController
  def update
    imei = params[:imei]
    vehicle = Vehicle.find_or_create_by(imei: imei)
    vehicle.update!(
      latitude: params[:lat].to_f,
      longitude: params[:lng].to_f,
      speed: params[:speed]&.to_f || 0
    )
    head :ok
  rescue => e
    Rails.logger.error "GPS Error: #{e}"
    head :ok  # Graceful for devices
  end

  def stream
    render json: {
      count: Vehicle.count,
      active: Vehicle.where("updated_at > ?", 5.minutes.ago).count,
      vehicles: Vehicle.limit(5).pluck(:imei, :latitude, :longitude, :speed)
    }
  end
end
