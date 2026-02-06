class GpsController < ApplicationController
  def update
    vehicle = Vehicle.find_or_create_by(imei: params[:imei])
    vehicle.update!(latitude: params[:lat], longitude: params[:lng])
    ActionCable.server.broadcast("gps_channel", {imei: vehicle.imei, lat: vehicle.latitude, lng: vehicle.longitude})
    head :ok
  end
end
