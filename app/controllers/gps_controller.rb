class GpsController < ApplicationController
  def update
    vehicle = Vehicle.find_or_initialize_by(imei: params[:imei])
    vehicle.update!(latitude: params[:lat], longitude: params[:lng], updated_at: Time.current)
    head :ok
  end
  
  def stream
    render plain: "GPS STREAM LIVE - #{Vehicle.count} active"
  end
end
