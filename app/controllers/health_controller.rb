class HealthController < ApplicationController
  def show
    render plain: "🟢 OK - Rails 8.1 + #{Vehicle.count} vehicles + #{Batch.count} batches"
  end
end
