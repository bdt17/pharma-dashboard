class DashboardController < ApplicationController
  def index
    @batches = Batch.order(created_at: :desc).limit(10) rescue []
    @vehicles = Vehicle.order(updated_at: :desc).limit(5) rescue []
    render layout: "application"
  end
end
