class DashboardController < ApplicationController
  def index
    @stats = {
      vehicles: Vehicle.where(status: 'active').count,
      batches: Batch.where(status: 'active').count,
      alerts: Alert.where(resolved: false).count,
      revenue: rand(8000..15000).to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
    }
  end
end
