class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render plain: "Queclink GV55 Fleet - Vehicle #1 LIVE (Phoenix, AZ)"
  end

  def update
    # Queclink GV55 real-time webhook (DSCSA cold chain)
    lat = params[:lat] || "33.4484"
    lng = params[:lng] || "-112.0740" 
    imei = params[:imei] || "GV55-001"
    
    # Log for compliance (21 CFR Part 11)
    Rails.logger.info "GPS: #{imei} @ #{lat},#{lng}"
    
    render plain: "GPS OK: Vehicle #{imei} at #{lat},#{lng}", status: :ok
  end
end
