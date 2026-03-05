class GpsController < ApplicationController
  def update
    vehicle = Vehicle.find_or_create_by(plate: params[:imei]) do |v|
      v.name = "GV55-#{params[:imei]}"
      v.latitude = params[:lat]
      v.longitude = params[:lng]
      v.status = 'online'
    end
    
    vehicle.update!(latitude: params[:lat], longitude: params[:lng], status: 'online')
    
    render json: { 
      status: 'GPS_UPDATED', 
      vehicle: vehicle.plate,
      coords: [params[:lat], params[:lng]]
    }
  end
end
