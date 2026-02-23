class HealthController < ApplicationController
  def index
    render json: {
      status: "Pharma Transport Enterprise v9.2 - OK",
      timestamp: Time.now.utc.iso8601,
      uptime: Time.now - Rails.application.config.start_time.to_i rescue 0,
      db: ActiveRecord::Base.connection.execute("SELECT 1") && "OK",
      vehicles: Vehicle.count,
      batches: Batch.count,
      rails: Rails.version
    }, status: 200
  end
end
