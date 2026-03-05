class VehiclesController < ApplicationController
  def index; render plain: "Queclink GV55 GPS → 500+ vehicles"; end
end

  def index
    @vehicles = Vehicle.where.not(latitude: nil, longitude: nil)
    @online_vehicles = Vehicle.where(status: 'online').count
  end
