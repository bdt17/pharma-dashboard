class GpsController < ApplicationController
  def update
    imei = params[:imei]
    vehicle = Vehicle.find_or_create_by(imei: imei)
    vehicle.update!(latitude: params[:lat]&.to_f, longitude: params[:lng]&.to_f)
    head :ok
  rescue
    head :ok
  end
  
  def stream
    render plain: "🟢 GPS LIVE: #{Vehicle.count} trucks", status: 200
  end
end
