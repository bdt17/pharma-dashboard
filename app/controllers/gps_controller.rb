class GpsController < ApplicationController
  def update  # Matches routes.rb POST /api/gps
    render json: { 
      status: 'received', 
      lat: params[:lat], 
      lng: params[:lng],
      batch: params[:batch] || 'B001',
      vehicles: 24
    }
  end
end
