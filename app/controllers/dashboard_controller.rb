class DashboardController < ApplicationController
  layout false
  
  def index
    @vehicles = 24
    @revenue = 12000
    @batches = 127
    render layout: false
  end
end
