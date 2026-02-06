class GpsController < ApplicationController
  def update
    vehicle = Vehicle.find_or_create_by(imei: params[:imei]) do |v|
      v.latitude = params[:lat]
      v.longitude = params[:lng] 
    end
    vehicle.update(latitude: params[:lat], longitude: params[:lng], updated_at: Time.current)
    head :ok, content_type: 'text/plain'
  end
  
  def stream
    render plain: "🚀 LIVE: #{Vehicle.count} vehicles tracked", status: 200
  end
end
