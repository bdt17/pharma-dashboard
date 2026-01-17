module Api
  class GpsController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def create
      vehicle = Vehicle.find_or_create_by(batch_id: params[:batch_id].to_i) do |v|
        v.lat = params[:lat]&.to_f || 0.0
        v.lng = params[:lng]&.to_f || 0.0
        v.speed = params[:speed]&.to_f || 0.0
        v.heading = params[:heading]&.to_f || 0.0
      end
      
      vehicle.touch
      render json: {
        status: 'received',
        vehicle_id: vehicle.id,
        position: { lat: vehicle.lat, lng: vehicle.lng, speed: vehicle.speed }
      }, status: :ok
    end
  end
end
