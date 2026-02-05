class GpsController < ApplicationController
  def vehicles
    vehicles = Vehicle.count > 0 ? Vehicle.all : []
    render json: vehicles.map { |v| {
      id: v.id,
      license_plate: v.license_plate || "PHARMA#{rand(100)}",
      lat: v.lat || 33.4484,
      lng: v.lng || -112.0740,
      status: v.status || 'idle'
    }}
  end

  def batches
    batches = Batch.count > 0 ? Batch.all : []
    render json: batches.map { |b| {
      id: b.id,
      name: b.name || "LOT-PHX-#{Time.now.strftime('%Y%m%d')}-#{rand(100)}",
      vehicle: b.vehicle&.license_plate || 'N/A',
      temp_status: b.temp_status || '2-8°C'
    }}
  end
end
