class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.all
    @batches = Batch.all
    @mrr_potential = Vehicle.count * 99
  end
end
