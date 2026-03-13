class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update]

  def update
    imei = params[:imei]
    lat = params[:lat]
    lng = params[:lng]
    render plain: "GPS Updated: #{imei} @ (#{lat},#{lng})", status: :ok
  end

  def stream
    render plain: "GPS Stream Active", status: :ok
  end
end
