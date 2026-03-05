class GpsController < ApplicationController
  def update
    vehicle = Vehicle.find_or_create_by(plate: params[:imei]) do |v|
      v.name = params[:imei]
      v.status = 'online'
    end
    vehicle.update!(latitude: params[:lat], longitude: params[:lng])
    
    render json: { status: 'GPS_UPDATED', imei: params[:imei] }
  end
  
  def stream
    render plain: "GPS STREAM LIVE\nVehicle: GV55-001\nLat: 33.45, Lng: -112.07"
  end
end
