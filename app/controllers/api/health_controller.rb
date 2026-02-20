class Api::HealthController < ActionController::API
  def show
    render json: {
      status: "ok",
      rails: Rails.version,
      ruby: RUBY_VERSION,
      vehicles: Vehicle.count,
      batches: Batch.count,
      ts: Time.now.utc.iso8601
    }, status: :ok
  end
end
