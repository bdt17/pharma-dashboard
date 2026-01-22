class DashboardController < ApplicationController
  def index
    render plain: "<h1>PHARMA DASHBOARD LIVE - 127 Batches</h1>", layout: false
  end
end
