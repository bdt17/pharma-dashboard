class GpsController < ApplicationController
  def index
    render plain: "GPS IoT Status: Queclink GV55 LIVE - /gps/receive TCP ready", status: :ok
  end

  def update
    head :ok
  end

  def receive
    # Queclink GV55 TCP endpoint
    req_body = request.body.read
    head :ok
  end
end
