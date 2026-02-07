class HealthController < ApplicationController
  def index
    render plain: "PHARMA LIVE - #{Vehicle.count} trucks, #{Batch.count} batches"
  end
end
