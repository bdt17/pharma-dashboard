# The GPS/telemetry ingestion endpoint real tracking devices post to.
# Device-authenticated (per-vehicle token), not user-authenticated -- a
# device has no Devise session. See Vehicle#api_token / #api_token_matches?.
class Api::V1::GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # A device that buffered readings through a dead zone reports the time
  # each was actually taken. We trust `captured_at` only within a sane
  # window -- back to MAX_BACKDATE (a realistic buffer depth) and a small
  # clock-skew tolerance ahead. Anything missing, unparseable, or outside
  # that window falls back to the receive time.
  MAX_BACKDATE = 7.days
  CLOCK_SKEW = 5.minutes

  def create
    vehicle = authenticate_device!
    return unless vehicle

    telemetry = vehicle.telemetries.new(telemetry_params)
    telemetry.recorded_at = captured_at
    # Attribute the reading to whatever delivery the truck is currently
    # carrying, so it lands on that shipment's temperature history and
    # feeds ExcursionMonitor. Devices don't know batch numbers; the
    # vehicle does.
    telemetry.batch = vehicle.current_batch

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

  # Accepts an ISO-8601 string or a Unix epoch (seconds). Returns nil for
  # anything absent, unparseable, or outside the accepted window -- the
  # Telemetry model then stamps the receive time (set_recorded_at).
  def captured_at
    raw = params[:captured_at].to_s.strip
    return nil if raw.blank?

    time = raw.match?(/\A\d+\z/) ? Time.zone.at(Integer(raw)) : Time.zone.iso8601(raw)
    return time if time.between?(MAX_BACKDATE.ago, CLOCK_SKEW.from_now)

    Rails.logger.warn("Api::V1::GpsController: captured_at #{raw.inspect} outside the accepted window; using receive time")
    nil
  rescue ArgumentError, TypeError
    Rails.logger.warn("Api::V1::GpsController: unparseable captured_at #{raw.inspect}; using receive time")
    nil
  end
end
