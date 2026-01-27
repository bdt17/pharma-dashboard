class GpsController < ApplicationController
  def update
    render json: {status: 'received', lat: params[:lat], lng: params[:lng], imei: params[:imei], vehicles: 24}
  end
  
  def stream
    render json: {lat: 33.4484, lng: -112.0740, vehicles: 24, active: 127}
  end
end
