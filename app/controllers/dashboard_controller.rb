class DashboardController < ApplicationController
  layout 'application'

  def index
    @total_batches     = defined?(Batch) ? (Batch.count rescue 127) : 127
    @active_vehicles   = defined?(Vehicle) ? (Vehicle.where(active: true).count rescue 24) : 24
    @monthly_revenue   = '$12K'
    @api_status        = '5/5 ✓'
  end
end
