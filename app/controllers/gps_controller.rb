class GpsController < ApplicationController
  def update
    # Thomas IT GPS strong params - Phoenix AZ pharma tracking
    gps_params = params.permit(:lat, :lng, :batch)
    
    render json: {
      status: 'received',
      lat: gps_params[:lat],
      lng: gps_params[:lng],
      batch: gps_params[:batch] || 'B001',
      vehicles: 24,
      location: 'Phoenix AZ'
    }
  end
end
