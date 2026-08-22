# Real fleet data for the dashboard -- scoped to the signed-in user's own
# organization via Pundit (VehiclePolicy), replacing the hardcoded
# `{ vehicles: 42, status: "Phase 10 LIVE" }` HomeController#vehicles used
# to return regardless of who asked or what was actually in the database.
class Api::V1::VehiclesController < ApplicationController
  before_action :authenticate_user!

  def index
    vehicles = policy_scope(Vehicle)
    render json: vehicles.map { |v| vehicle_json(v) }
  end

  def show
    vehicle = Vehicle.find(params[:id])
    authorize vehicle, :show?
    render json: vehicle_json(vehicle)
  end

  private

  def vehicle_json(vehicle)
    vehicle.as_json(only: [ :id, :name, :identifier, :plate, :status, :latitude, :longitude, :speed, :heading, :last_ping_at ])
  end
end
