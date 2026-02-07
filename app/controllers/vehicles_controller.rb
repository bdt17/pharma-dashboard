class VehiclesController < ApplicationController
  def index
    @vehicles = Vehicle.limit(10) rescue []
    render plain: "VEHICLES OK (#{@vehicles.size})"
  end
end
