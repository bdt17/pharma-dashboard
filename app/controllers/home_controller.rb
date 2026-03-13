class HomeController < ApplicationController
  def index
    @title = "PHARMA TRANSPORT DASHBOARD"
  end
  
  def vehicles
    render plain: "🚛 VEHICLE FLEET MANAGEMENT\n\n✅ Cold Chain Monitoring\n✅ Real-time GPS\n✅ DEA/FDA Compliance\n\nPhase 10 Enterprise LIVE", layout: "application"
  end
  
  def gps
    render plain: "🛰️ GPS TRACKING DASHBOARD\n\n✅ Live Vehicle Locations\n✅ IoT Telemetry\n✅ Geofence Alerts\n✅ Chain of Custody\n\nPhase 10 Enterprise LIVE", layout: "application"
  end
end
