class Api::V1::LocationsController < ApplicationController
  # no CSRF filters in API mode

  def create
    vehicle = Vehicle.find(params[:vehicle_id])

    location = vehicle.location_points.create!(
      latitude:  params[:latitude],
      longitude: params[:longitude],
      speed:     params[:speed],
      recorded_at: Time.current
    )

    vehicle.update!(
      current_latitude:  params[:latitude],
      current_longitude: params[:longitude]
    )

    render json: { status: "ok", location_id: location.id }
  end
end
