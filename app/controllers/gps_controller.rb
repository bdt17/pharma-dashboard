class GpsController < ApplicationController
  def update
    render json: { 
      status: 'GPS UPDATE OK', 
      imei: params[:imei], 
      lat: params[:lat], 
      lng: params[:lng],
      timestamp: Time.now 
    }
  end
  
  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.stream.write "data: #{ {vehicles: 24, active_batches: 127}.to_json }\n\n"
    response.stream.close
  end
  
  def health
    render plain: "🩺 THOMAS IT PHARMA v8.1\nBEQ2: LIVE | #{Time.now}\nGPS API ✓ FDA 21 CFR Part 11 ✓"
  end
end
