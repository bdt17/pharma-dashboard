class DashboardController < ApplicationController
  def index
    @vehicles = Vehicle.all
    @batches = Batch.all
  rescue
    @vehicles = []
    @batches = []
  end
end
  def index
    @vehicles = Vehicle.all rescue []
    @batches = Batch.all rescue []
  end
