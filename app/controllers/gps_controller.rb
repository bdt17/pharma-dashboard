class GpsController < ApplicationController
  # GPS data is often pushed from external devices, so authentication is disabled here.
  skip_before_action :authenticate_user!, raise: false

  # GET /gps/stream
  # Returns a simple response confirming that the GPS WebSocket / ActionCable stream is active.
  def stream
    render plain: 'ActionCable WebSocket GPS stream LIVE'
  end

  # POST /gps/update
  # Accepts incoming GPS updates from a device or test script and returns a JSON confirmation.
  def update
    render json: {
      status: 'gps_updated',
      vehicle: 'PHARMA-001',
      lat: 33.4484,
      lng: -112.0740,
      speed: 65,
      timestamp: Time.now.utc.iso8601
    }
  end
end
