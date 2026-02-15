class HealthchecksController < ApplicationController
  def index   # /api/health
    render json: { status: "healthy", time: Time.now.utc }, status: 200
  end
  
  def show    # /health  
    render plain: "OK", status: 200
  end
end
