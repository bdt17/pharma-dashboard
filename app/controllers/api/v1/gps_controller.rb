module Api
  module V1
    class GpsController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def update
        Telemetry.create!(
          vehicle_id: params[:vehicle_id],
          lat: params[:lat]&.to_f || 0,
          lng: params[:lng]&.to_f || 0,
          speed: params[:speed]&.to_f || 0,
          temp: params[:temp]&.to_f || 0,
          battery: params[:battery]&.to_f || 0,
          recorded_at: Time.current
        )
        render json: {status: 'success', vehicle_id: params[:vehicle_id]}
      end
    end
  end
end
