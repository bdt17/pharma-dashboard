class Api::HealthController < ApplicationController
  def index
    render json: {
      status: "ok",
      rails: Rails.version,
      ruby:  RUBY_VERSION,
      vehicles: Vehicle.count,
      batches:  Batch.count,
      ts: Time.now.utc.iso8601
    }
  end
end
