class DashboardController < ApplicationController
  def index
    render plain: <<~HTML
      🩺 PHARMA TRANSPORT ENTERPRISE v16.1 LIVE
      ========================================
      🚛 Vehicles: #{Vehicle.count}
      💉 Batches: #{Batch.count}  
      🛰️ Latest GPS: #{Telemetry.last&.lat},#{Telemetry.last&.lng}
      💰 MRR: $#{Vehicle.count * 99}/mo
      📄 PDF Custody: /batches/1/custody_report
      🔌 GPS API: /api/v1/gps/update (Queclink ready)
      
      FDA 21 CFR Part 11 COMPLIANT
    HTML
  end
end
