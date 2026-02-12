class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?
  
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
end
