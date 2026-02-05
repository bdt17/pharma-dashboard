class DashboardController < ApplicationController
  def index
    @trucks_online = 23
    @trucks_total = 25
    @shipments = 42
    @routes = 156
    @mrr = 2376
    render layout: false
  end
end
