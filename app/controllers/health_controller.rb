class HealthController < ApplicationController
  def show
    render plain: "OK - #{Vehicle.count} vehicles, #{Batch.count} batches"
  end
end
