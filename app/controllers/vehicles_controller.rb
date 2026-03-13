class VehiclesController < ApplicationController
  def index
    render plain: "Drone Fleet: 4 vehicles active | GPS tracking operational", layout: false
  end
end
