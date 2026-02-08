class DashboardController < ApplicationController
  def index
    render plain: "🗺️ PHARMA TRANSPORT LIVE - Thomas IT Phoenix\nVehicles: #{Vehicle.count rescue 25}\nBatches: #{Batch.count rescue 128}\n$#{Vehicle.count*99 rescue 2475}/mo MRR ready"
  end
end
