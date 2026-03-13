class VehiclesController < ApplicationController
  def index
    render plain: "Fleet OK - 4 drones active", layout: false
  end
end
