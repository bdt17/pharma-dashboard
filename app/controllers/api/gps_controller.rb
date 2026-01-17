
module Api
  class GpsController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def create
      # Simple response - no DB needed yet
      render json: {
        status: 'received',
        message: 'Phase 14 GPS LIVE',
        position: {
          lat: params[:lat]&.to_f || 0.0,
          lng: params[:lng]&.to_f || 0.0,
          speed: params[:speed]&.to_f || 0.0
        }
      }, status: :ok
    end
  end
end

