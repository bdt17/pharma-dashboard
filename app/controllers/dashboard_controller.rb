class DashboardController < ApplicationController
  def index
    @vehicles_count = 6  # Production demo data
    @batches_count = 1
    @mrr = @vehicles_count * 99  # $594 MRR display
  end
end
