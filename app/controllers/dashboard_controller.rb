class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.all.order(speed: :desc).limit(12)
    @revenue_projection = Vehicle.count * 99
    @batches = Batch.count
  end
end
