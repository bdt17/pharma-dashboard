class DashboardController < ApplicationController
  def index
    render plain: "🩺 PHARMA TRANSPORT ENTERPRISE v16.1 LIVE\n🚛 #{Vehicle.count} VEHICLES | 💉 #{Batch.count} BATCHES | 💰 $#{Vehicle.count*99}/mo MRR\n📄 PDF: /batches/1/custody_report | 🔌 GPS: /api/v1/gps/update"
  end
end
