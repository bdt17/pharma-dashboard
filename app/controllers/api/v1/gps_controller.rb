module Api
  module V1
    class GpsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:update, :stream]
      
      def update
        telemetry = Telemetry.create!(
          vehicle_id: params[:vehicle_id],
          lat: params[:lat]&.to_f || 0.0,
          lng: params[:lng]&.to_f || 0.0,
          speed: params[:speed]&.to_f || 0.0,
          temp: params[:temp]&.to_f || 0.0,
          battery: params[:battery]&.to_f || 0.0,
          signal_strength: params[:signal_strength]&.to_i || 99,
          recorded_at: Time.current
        )
        
        ActionCable.server.broadcast("gps_#{params[:vehicle_id]}", {
          id: telemetry.id,
          vehicle_id: telemetry.vehicle_id,
          lat: telemetry.lat,
          lng: telemetry.lng,
          speed: telemetry.speed,
          temp: telemetry.temp,
          battery: telemetry.battery,
          timestamp: telemetry.recorded_at.iso8601
        })
        
        render json: { 
          status: 'created', 
          telemetry_id: telemetry.id,
          vehicle_id: telemetry.vehicle_id,
          position: [telemetry.lat, telemetry.lng]
        }, status: :created
      end
      
      def stream
        render json: { status: 'WebSocket stream ready' }, status: :ok
      end
    end
  end
end
