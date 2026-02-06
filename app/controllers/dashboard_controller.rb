class DashboardController < ApplicationController
  def index
    @batches = Batch.order(created_at: :desc).limit(10)
    @vehicles = Vehicle.order(updated_at: :desc).limit(5)
    render layout: "application"
  end
end
