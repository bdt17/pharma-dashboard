class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def update
    render plain: "GPS OK: #{params[:imei]}", status: :ok
  end
  def stream
    render plain: "GPS STREAM LIVE", status: :ok
  end
end
