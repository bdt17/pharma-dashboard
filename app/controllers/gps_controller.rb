class GpsController < ApplicationController
  def index
    render json: { status: 'GPS tracking ready', count: 42 }, status: 200
  end

  def create
    render json: { status: 'GPS data received' }, status: 201
  end

  def stream
    render plain: "GPS Stream Active", status: 200
  end
end
  def create
    render json: { status: 'GPS data received', count: 1 }, status: 201
  end
