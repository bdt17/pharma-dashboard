class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def update
    imei = params[:imei]
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f
    
    # Log GPS data (Phase 2 LIVE)
    Rails.logger.info "GPS UPDATE: IMEI=#{imei} LAT=#{lat} LNG=#{lng}"
    
    # TODO: Save to Vehicle model
    head :no_content # 204 = correct API response
  end
  
  def stream
    render plain: "GPS LIVE - ActionCable WebSocket ready"
  end
end
