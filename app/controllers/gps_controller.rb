class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :update

  def update
    # Queclink GV55 real-time GPS webhook
    lat = params[:lat] || params[:latitude]
    lng = params[:lng] || params[:longitude]
    vehicle_id = params[:imei] || "GV55-1"
    
    # Log GPS data (your cold chain compliance)
    Rails.logger.info "GPS UPDATE: Vehicle=#{vehicle_id} Lat=#{lat} Lng=#{lng}"
    
    # TODO: Save to Vehicle model
    head :ok, 'Content-Type' => 'text/plain'
  end
  
  def index
    @vehicles = Vehicle.all # Your Queclink fleet
    render 'gps/index'
  end
end
