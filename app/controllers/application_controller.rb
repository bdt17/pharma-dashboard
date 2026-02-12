class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?
  
  def index
    render plain: "PHARMA DASHBOARD v8.1 LIVE - Thomas IT", status: 200
  end

  def health
    render json: {status: "ok", timestamp: Time.now.utc.iso8601}, status: 200
  end

  def vehicles
    render json: [], status: 200
  end

  def batches
    render json: [], status: 200
  end

  def gps_update
    render json: {received: true}, status: 200
  end

  def gps_stream
    render plain: "", status: 200
  end
end
