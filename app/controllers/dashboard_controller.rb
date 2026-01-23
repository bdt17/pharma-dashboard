class DashboardController < ApplicationController
  def index
    @health = { batches: 127, status: 'live' }  # Hardcode for now
  end

  def batches
    render json: { count: 127 }  # Your pharma batches
  end
end
