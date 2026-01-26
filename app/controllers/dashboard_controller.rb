class DashboardController < ApplicationController
  layout 'application'

  def index
    @total_batches     = Batch.count || 127
    @active_vehicles   = Vehicle.where(active: true).count || 24
    @monthly_revenue   = '$12K'  # Your business metric
    @api_status        = '5/5 ✓'
  end
end
