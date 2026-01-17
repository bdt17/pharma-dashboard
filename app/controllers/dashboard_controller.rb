class DashboardController < ApplicationController
  def index
    @stats = {
      vehicles: 24,
      batches: 127, 
      alerts: 3,
      revenue: "12"
    }
  end
end
