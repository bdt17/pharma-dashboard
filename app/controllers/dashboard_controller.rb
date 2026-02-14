class DashboardController < ApplicationController
  def index
    @mrr = 4653
    @batches = 127
    @vehicles = 23
    render layout: 'application'
  end
end
