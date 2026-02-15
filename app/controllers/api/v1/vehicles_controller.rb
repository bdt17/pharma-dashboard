class Api::V1::VehiclesController < ApplicationController
  def show
    vehicle = Vehicle.find(params[:id])
    render json: vehicle.slice(:id, :name, :latitude, :longitude, :status)
  end
end
