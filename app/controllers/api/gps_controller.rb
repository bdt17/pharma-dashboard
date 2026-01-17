module Api
  class GpsController < ApplicationController
    def create
      vehicle = Vehicle.find_or_initialize_by(batch_id: params[:batch_id])
      vehicle.update!(
        lat: params[:lat].to_f,
        lng: params[:lng].to_f, 
        speed: params[:speed].to_f,
        heading: params[:heading]&.to_f || 0
      )
      
      render json: { 
        status: 'received', 
        vehicle_id: vehicle.id,
        position: { lat: vehicle.lat, lng: vehicle.lng }
      }, status: :created
    end
  end
end
