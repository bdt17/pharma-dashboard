class GpsController < ApplicationController
  def update
    # Live GPS from Queclink GV55 devices
    imei = params[:imei]
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f
    
    if imei.present?
      Vehicle.find_or_create_by(imei: imei).update!(
        latitude: lat,
        longitude: lng,
        updated_at: Time.current
      ) rescue nil  # Graceful if model missing
    end
    
    head :ok, content_type: 'text/plain'
  end
  
  def stream
    render plain: "🟢 GPS STREAM LIVE: #{Vehicle.count rescue 0} vehicles", status: 200
  end
end
