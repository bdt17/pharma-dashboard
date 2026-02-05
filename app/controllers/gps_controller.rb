class GpsController < ApplicationController
  def create   # POST /gps_post
    render json: { status: "GPS received", time: Time.now.utc }, status: 201
  end
  
  def stream   # GET /gps_stream
    render plain: "GPS Stream Active", status: 200
  end
end
