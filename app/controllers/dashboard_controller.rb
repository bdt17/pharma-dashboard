class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.last(12)
    @batches  = Batch.where(active: true).count
  end
end
