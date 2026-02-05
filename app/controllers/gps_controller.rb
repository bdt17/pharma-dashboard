class GpsController < ApplicationController
  def index
    render json: { status: 'GPS tracking active', vehicles: 42 }, status: 200
  end

  def create
    render json: { 
      status: 'GPS coordinates received', 
      received_at: Time.now.utc.iso8601 
    }, status: 201
  end

  def stream
    render plain: "GPS Stream Active - #{Time.now}", status: 200
  end

  def update
    render json: { status: 'GPS update processed' }, status: 200
  end
end
