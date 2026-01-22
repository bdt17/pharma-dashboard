class DashboardController < ApplicationController
  def index
    @batches = 127
    @vehicles = 24
    @revenue = '$12K'
  end
end
