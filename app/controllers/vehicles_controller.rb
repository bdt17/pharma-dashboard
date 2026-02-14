class VehiclesController < ApplicationController
  def index
    @vehicles = [{id: 1, name: 'Truck-001', status: 'Active'}]
    render layout: 'application'
  end
end
