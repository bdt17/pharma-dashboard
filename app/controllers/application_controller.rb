class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?
  
  # In-memory GPS vehicle store (Phase 2)
  @@vehicles = []
  
  def index
    render plain: "PHARMA DASHBOARD v8.1 LIVE - Thomas IT", status: 200
  end
  
  def health
    render json: {status: "ok", timestamp: Time.now.utc.iso8601}, status: 200
  end
  
  def vehicles
    render json: @@vehicles, status: 200
  end
  
  def batches
    render json: [], status: 200
  end
  
  def gps_update
    # Parse Queclink GPS data
    imei = params[:imei]
    lat = params[:lat]&.to_f
    lng = params[:lng]&.to_f
    speed = params[:speed]&.to_f || 0
    
    if imei && lat && lng
      # Update or create vehicle
      vehicle = @@vehicles.find { |v| v[:imei] == imei } || {}
      vehicle[:imei] = imei
      vehicle[:lat] = lat
      vehicle[:lng] = lng
      vehicle[:speed] = speed
      vehicle[:updated_at] = Time.now.utc.iso8601
      vehicle[:location] = "Phoenix, AZ" # Thomas IT HQ
      
      @@vehicles.delete_if { |v| v[:imei] == imei }
      @@vehicles << vehicle
      render json: {received: true, vehicle: vehicle}, status: 200
    else
      render json: {error: "Missing GPS params"}, status: 400
    end
  end
  
  def gps_stream
    render plain: "", status: 200
  end
end
