class DashboardController < ApplicationController
  def index
    render plain: "PHARMA TRANSPORT LIVE - Thomas IT Phoenix\nVehicles: 25\nBatches: 128\n$2475/mo MRR ready\nhttps://pharma-dashboard-beq2.onrender.com/billing"
  end
end
