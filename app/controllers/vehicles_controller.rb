class VehiclesController < ApplicationController
  def show
    @vehicle_id = params[:id]
    @status = "Active"
    @eta = "8min"
    @location = "Scottsdale"
    render layout: false
  end
end
