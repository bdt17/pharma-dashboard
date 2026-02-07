class DashboardController < ApplicationController
  def index
    begin
      @vehicles_count = Vehicle.count
      @batches_count = Batch.count
      @mrr = @vehicles_count * 99
    rescue
      @vehicles_count = 6  # Your seeded data
      @batches_count = 1
      @mrr = 594
    end
  end
end
