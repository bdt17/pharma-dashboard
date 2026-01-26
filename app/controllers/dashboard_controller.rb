class DashboardController < ApplicationController
  def index
    render plain: '<h1>Thomas IT Pharma Transport LIVE</h1>', layout: false, status: 200
  end
end
