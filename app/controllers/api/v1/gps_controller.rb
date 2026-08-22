# The GPS/telemetry ingestion endpoint real tracking devices post to.
# Device-authenticated (per-vehicle token), not user-authenticated -- a
# device has no Devise session. See Vehicle#api_token / #api_token_matches?.
class Api::V1::GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    vehicle = authenticate_device!
    return unless vehicle

    telemetry = vehicle.telemetries.new(telemetry_params)

    if telemetry.save
      head :created
    else
      render json: { errors: telemetry.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  # Deliberately the same response for "no such IMEI" and "wrong token" --
  # a real device (or an attacker) shouldn't be able to tell which one is
  # true by probing.
  def authenticate_device!
    vehicle = Vehicle.find_by(imei: params[:imei])
    token = request.headers["X-Device-Token"]

    if vehicle&.api_token_matches?(token)
      vehicle
    else
      head :unauthorized
      nil
    end
  end

  def telemetry_params
    # ActiveRecord type-casts these string params to the underlying float
    # columns on assignment -- no manual conversion needed.
    params.permit(:lat, :lng, :speed, :temp, :battery, :signal_strength)
  end
end
