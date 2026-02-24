module Api
  module V1
    class GpsController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def update
        telemetry = Telemetry.create!(
          vehicle_id: params[:vehicle_id],
          lat: params[:lat]&.to_f,
          lng: params[:lng]&.to_f, 
          speed: params[:speed]&.to_f,
          temp: params[:temp]&.to_f,
          battery: params[:battery]&.to_f,
          recorded_at: Time.current
        )
        render json: {status: 'created', id: telemetry.id}
      end
    end
  end
end
