class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  
  def index
    @vehicles_count = Vehicle.count
    @batches_count = Batch.count
    @latest_telemetry = Telemetry.last
    render layout: "application"
  end
end
