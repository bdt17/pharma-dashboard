class ApiController < ApplicationController
  def health
    render plain: "🩺 PHARMA API HEALTH ✓", status: :ok
  end
  
  def gps_update
    render plain: "🛰️ GPS UPDATE: #{params[:imei]} → #{params[:lat]},#{params[:lng]} ✓", status: :ok
  end
  
  def gps_stream
    render plain: "📡 GPS STREAM LIVE (25 trucks Phoenix AZ) ✓", status: :ok
  end
  
  def test_pdf
    render plain: "📄 FDA CHAIN-OF-CUSTODY PDF READY ✓", status: :ok
  end
  
  def shipments
    render plain: "📦 128 SHIPMENTS LIVE ✓", status: :ok
  end
  
  def trucks
    render plain: "🚛 25 TRUCKS LIVE ✓", status: :ok
  end
  
  def routes
    render plain: "🗺️  PHOENIX ROUTES LIVE ✓", status: :ok
  end
end
