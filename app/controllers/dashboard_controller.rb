class DashboardController < ApplicationController
  def index
    @batches = Batch.all
    @vehicles = Vehicle.where(status: 'online')
    @total_batches = Batch.count
    @online_vehicles = Vehicle.where(status: 'online').count
  end
end
