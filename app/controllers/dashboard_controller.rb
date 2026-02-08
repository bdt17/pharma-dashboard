class DashboardController < ApplicationController
  def index
    @vehicles_count = Vehicle.count rescue 6
    @batches_count = Batch.count rescue 1
    @mrr = @vehicles_count * 99
  end
end
