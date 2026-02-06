class GpsController < ApplicationController
  def update
    imei = params[:imei]
    return head :bad_request unless imei
    
    vehicle = Vehicle.find_or_create_by(imei: imei)
    vehicle.update!(
      latitude: params[:lat]&.to_f,
      longitude: params[:lng]&.to_f,
      speed: params[:speed]&.to_f
    )
    
    head :ok, content_type: 'text/plain'
  rescue => e
    head :internal_server_error
  end
  
  def stream
    count = Vehicle.where("updated_at > ?", 5.minutes.ago).count
    render plain: "🟢 LIVE GPS: #{Vehicle.count} total | #{count} active", status: :ok
  end
end
