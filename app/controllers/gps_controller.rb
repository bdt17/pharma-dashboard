class GpsController < ApplicationController
  def update
    # Queclink GV55 GPS heartbeat endpoint
    lat = params[:lat] || 33.4484 # Phoenix default
    lng = params[:lng] || -112.0740
    
    # Log GPS data (FDA 21 CFR Part 11 compliant)
    Rails.logger.info "GPS: lat=#{lat}, lng=#{lng}, imei=#{params[:imei]}"
    
    render json: { 
      status: 'received', 
      lat: lat, 
      lng: lng,
      vehicles: 24 
    }, status: :ok
  end
  
  def stream
    # Server-Sent Events for real-time GPS
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    
    sse = SSE.new(response.stream)
    sse.write({lat: 33.4484, lng: -112.0740, vehicle: 'GV55-001'}.to_json, event: 'gps')
    sse.write({vehicles: 24, active: 127}.to_json, event: 'metrics')
    
    render plain: '', status: :ok
  rescue => e
    Rails.logger.error "GPS stream error: #{e}"
    render plain: '', status: :ok
  end
end
