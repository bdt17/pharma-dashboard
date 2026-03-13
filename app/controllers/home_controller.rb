class HomeController < ApplicationController
  def index
    @title = "PHARMA TRANSPORT DASHBOARD"
  end
  
  def vehicles
    @page_title = "Fleet Management"
    @content = "🚛 COLD CHAIN FLEET\n✅ 24/7 GPS Tracking\n✅ Temperature Monitoring\n✅ DEA/FDA Compliance\n✅ Maintenance Alerts"
  end
  
  def gps
    @page_title = "GPS Tracking"
    @content = "🛰️ REAL-TIME TRACKING\n✅ Live Vehicle Locations\n✅ Geofence Alerts\n✅ IoT Telemetry\n✅ ETA Predictions"
  end
end
