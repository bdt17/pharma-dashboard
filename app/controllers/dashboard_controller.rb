class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.limit(10)
    @batches = Batch.limit(5)
  end
end
