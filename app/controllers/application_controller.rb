class ApplicationController < ActionController::Base
  def index
    render plain: "PHARMA DASHBOARD v8.1 LIVE", status: 200
  end
  
  def health
    render json: {status: "ok"}, status: 200
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
