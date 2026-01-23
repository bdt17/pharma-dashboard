class DashboardController < ApplicationController
  def index
  end
  
  def batches
    @batches = Batch.all  # Your pharma batches
    render json: { count: @batches.count }
  end
end
