class GpsController < ApplicationController
  def vehicles
    vehicles = Vehicle.all.limit(50)
    render json: vehicles.map { |v|
      {
        id: v.id,
        license_plate: v.license_plate,
        lat: v.lat,
        lng: v.lng,
        status: v.status
      }
    }
  end

  def batches
    batches = Batch.all.limit(50)
    render json: batches.map { |b|
      {
        id: b.id,
        name: b.name,
        vehicle_id: b.vehicle_id,
        temp_status: b.temp_status,
        compliance_status: b.compliance_status
      }
    }
  end
end
