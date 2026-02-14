class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?

  def index
    render "dashboard/index"
  end

  def dashboard
    render "dashboard/index"
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
    render json: {status: "GPS OK"}, status: 200
  end
end
