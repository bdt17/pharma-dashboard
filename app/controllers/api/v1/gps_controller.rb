class Api::V1::GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    vehicle = Vehicle.find_by(plates: params[:plate]) || Vehicle.first # Fallback
    return head :not_found unless vehicle

    vehicle.update!(
      latitude: params[:lat].to_f,
      longitude: params[:lng].to_f,
      speed: params[:speed]&.to_f || 0,
      heading: params[:heading]&.to_i || 0,
      last_ping: Time.current
    )

    # Real-time broadcast (ActionCable ready)
    ActionCable.server.broadcast("gps_all", {
      vehicle_id: vehicle.id,
      lat: vehicle.latitude,
      lng: vehicle.longitude,
      speed: vehicle.speed,
      timestamp: vehicle.last_ping
    })

    head :ok, location: api_v1_gps_path(vehicle.id)
  end

  def index
    render json: Vehicle.all.map { |v| { id: v.id, lat: v.latitude, lng: v.longitude } }
  end

  def show
    vehicle = Vehicle.find(params[:id])
    render json: vehicle.as_json(only: [ :latitude, :longitude, :speed, :last_ping ])
  end
end
