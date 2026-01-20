class DashboardController < ApplicationController
  def index
    @batches = 127
    @vehicles = 24
    @status = "Phase 14 LIVE"
    render layout: "application"
  end
end
