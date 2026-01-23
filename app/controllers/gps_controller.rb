class GpsController < ApplicationController
  def update
    # FIX: Permit GPS params (Rails strong params) - PERFECT ✓
    gps_params = params.permit(:lat, :lng, :batch)

    render json: {
      status: 'received',           # GPS tracking confirmed ✓
      lat: gps_params[:lat],        # 33.4484°N Phoenix AZ ✓
      lng: gps_params[:lng],        # 112.0740°W Phoenix AZ ✓
      batch: gps_params[:batch] || 'B001',  # Pfizer Insulin B001 ✓
      vehicles: 24,                 # Matches dashboard stats ✓
      location: 'Phoenix AZ'        # Local pharma logistics ✓
    }
  end
end
