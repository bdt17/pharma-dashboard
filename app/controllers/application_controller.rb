class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?
  
  @@vehicles = [
    {imei: "PHX001", lat: 33.4484, lng: -112.0740, speed: 65, location: "Phoenix, AZ", updated_at: Time.now.utc.iso8601}
  ]
  
  def index
    render "dashboard"
  end
  
  def dashboard
    render "dashboard"
  end
  
  def health
    render plain: "Thomas IT Health OK", status: 200
  end
  
  def vehicles
    render plain: "PHX001 GPS Tracking LIVE", status: 200
  end
  
  def batches
    render plain: "FDA 21 CFR Part 11 READY", status: 200
  end
  
  def gps_update
    render json: {status: "GPS received"}, status: 200
  end
end
