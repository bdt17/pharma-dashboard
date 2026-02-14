class DashboardController < ApplicationController
  def index
    @mrr = 4653
    @batches_active = 127
    @vehicles_live = 23
    render layout: 'application'
  end
end
