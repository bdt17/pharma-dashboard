class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.limit(10)
    @batches = Batch.limit(10)
  rescue
    @vehicles = []
    @batches = []
  end
end
