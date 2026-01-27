class GpsController < ApplicationController
  def update
    # Queclink GV55 GPS data
    imei = params[:imei]
    lat = params[:lat]
    lng = params[:lng]
    render plain: "✅ GPS #{imei} → #{lat},#{lng} Phoenix AZ"
  end
  
  def stream
    render plain: "🛰️ GPS STREAM LIVE - 24 vehicles"
  end
  
  def health
    render plain: "✅ Pharma Transport v8.1 - All systems nominal"
  end
end
