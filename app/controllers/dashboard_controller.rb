class DashboardController < ApplicationController
  def index
    render plain: "🩺 PHARMA TRANSPORT ENTERPRISE v16.1 LIVE\n#{Vehicle.count} VEHICLES | #{Batch.count} BATCHES | $#{Vehicle.count*99}/mo MRR POTENTIAL\n📄 DEMO PDF: /batches/1/custody_report"
  end
