class GpsController < ApplicationController
  def vehicles
    @vehicles = Vehicle.all
    render json: @vehicles.map { |v| { 
      id: v.id, 
      license_plate: v.license_plate,
      lat: v.lat, 
      lng: v.lng,
      status: v.status 
    } }
  end

  def batches
    @batches = Batch.all
    render json: @batches.map { |b| { 
      id: b.id, 
      name: b.name,
      vehicle: b.vehicle.license_plate,
      temp_status: b.temp_status
    } }
  end
end
