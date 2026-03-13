class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def update
    render plain: "GPS OK: #{params[:imei]} (#{params[:lat]},#{params[:lng]})", layout: false, status: 200
  end
  
  def stream
    render plain: "GPS STREAM LIVE - GV55 Active", layout: false, status: 200
  end
end
