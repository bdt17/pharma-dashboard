class DashboardController < ApplicationController
  # BYPASS ALL LAYOUTS - DIRECT HTML
  layout nil
  
  def index
    render plain: <<~HTML, layout: false, content_type: 'text/html'
<!DOCTYPE html>
<html style="background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%) !important; margin: 0; padding: 0;">
<head>
  <title>Pharma Transport</title>
  <meta name="viewport" content="width=device-width">
  <style>
    * { all: revert !important; margin: 0 !important; padding: 0 !important; box-sizing: border-box !important; }
    html, body { 
      background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%) !important;
      color: white !important;
      font-family: -apple-system, sans-serif !important;
      min-height: 100vh !important;
    }
    a { color: #60BDD1 !important; text-decoration: none !important; }
  </style>
</head>
<body>
  <div style="max-width: 1200px; margin: 2rem auto; padding: 2rem;">
    <h1 style="font-size: 3rem; color: #60BDD1 !important; margin-bottom: 1rem;">💉 Pharma Transport Dashboard</h1>
    <p style="color: #C0BEC6 !important; font-size: 1.2rem; margin-bottom: 3rem;">Phase 14 LIVE • 24 GPS Vehicles • 127 Batches</p>
    
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem;">
      <div style="background: rgba(255,255,255,0.1) !important; padding: 2.5rem; border-radius: 1rem; border: 1px solid rgba(9,132,192,0.3) !important; text-align: center;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">🚛</div>
        <h3 style="color: #C0BEC6 !important;">Live Vehicles</h3>
        <div style="font-size: 3.5rem; font-weight: 900; color: #60BDD1 !important;">24</div>
      </div>
      
      <div style="background: rgba(255,255,255,0.1) !important; padding: 2.5rem; border-radius: 1rem; border: 1px solid rgba(9,132,192,0.3) !important; text-align: center;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">📦</div>
        <h3 style="color: #C0BEC6 !important;">Active Batches</h3>
        <div style="font-size: 3.5rem; font-weight: 900; color: #60BDD1 !important;">127</div>
      </div>
      
      <div style="background: rgba(255,215,0,0.2) !important; padding: 2.5rem; border-radius: 1rem; border: 2px solid #FFD700 !important; text-align: center;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">💰</div>
        <h3 style="color: #C0BEC6 !important;">Revenue</h3>
        <div style="font-size: 3.5rem; font-weight: 900; color: #FFD700 !important;">$12K</div>
      </div>
    </div>
    
    <div style="text-align: center; margin-top: 3rem;">
      <a href="https://www.pharmatransport.org/" style="background: linear-gradient(90deg, #0984C0, #60BDD1) !important; color: white !important; padding: 1.5rem 3rem; border-radius: 1rem; font-size: 1.3rem; font-weight: 800; box-shadow: 0 15px 35px rgba(9,132,192,0.5) !important; display: inline-block;">
        🚀 Launch Production Platform
      </a>
    </div>
  </div>
</body>
</html>
    HTML
  end
end

