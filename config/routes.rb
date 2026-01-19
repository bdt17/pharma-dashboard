Rails.application.routes.draw do
  get "/dashboard", to: proc { [200, { "Content-Type" => "text/html" }, [
    <<~HTML
<!DOCTYPE html>
<html style="background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%) !important; margin: 0 !important; padding: 0 !important; height: 100vh !important;">
<head>
  <title>Pharma Transport Dashboard</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    * { all: revert !important; margin: 0 !important; padding: 0 !important; box-sizing: border-box !important; }
    html, body { 
      background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%) !important !important;
      color: #FFFFFF !important;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif !important;
      min-height: 100vh !important;
      line-height: 1.6 !important;
    }
    a, a:visited, a:hover, a:active { color: #60BDD1 !important; text-decoration: none !important; }
  </style>
</head>
<body style="background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%) !important;">
  <div style="max-width: 1200px; margin: 0 auto; padding: 2rem;">
    <div style="background: rgba(255,255,255,0.08) !important; border: 1px solid rgba(9,132,192,0.3) !important; border-radius: 2rem; padding: 3rem; text-align: center; margin-bottom: 3rem; backdrop-filter: blur(20px) !important;">
      <div style="font-size: 5rem; margin-bottom: 1rem;">💉</div>
      <h1 style="font-size: 3rem; font-weight: 900; color: #FFFFFF !important; margin-bottom: 1rem;">Pharma Transport Dashboard</h1>
      <p style="color: #C0BEC6 !important; font-size: 1.4rem; margin-bottom: 2rem;">Phase 14 LIVE • 24 GPS Vehicles • 127 Batches • $12K Revenue</p>
      <a href="https://www.pharmatransport.org/" style="background: linear-gradient(90deg, #0984C0, #60BDD1) !important; color: #FFFFFF !important; padding: 1.5rem 4rem; border-radius: 1.5rem; font-size: 1.3rem; font-weight: 800; box-shadow: 0 20px 40px rgba(9,132,192,0.5) !important; display: inline-block;">
        🚀 Launch Production Platform
      </a>
    </div>
    
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 2rem;">
      <div style="background: rgba(255,255,255,0.08) !important; border: 2px solid rgba(9,132,192,0.4) !important; border-radius: 1.5rem; padding: 3rem 2rem; text-align: center; backdrop-filter: blur(20px) !important;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">🚛</div>
        <h3 style="color: #C0BEC6 !important; font-size: 1.3rem; margin-bottom: 1rem; font-weight: 500;">Live Vehicles</h3>
        <div style="font-size: 3.8rem; font-weight: 900; color: #60BDD1 !important; text-shadow: 0 0 20px rgba(96,189,209,0.6) !important;">24</div>
        <p style="color: #AAA7B0 !important; font-size: 1.1rem;">GPS Tracked • Real-time</p>
      </div>
      
      <div style="background: rgba(255,255,255,0.08) !important; border: 2px solid rgba(9,132,192,0.4) !important; border-radius: 1.5rem; padding: 3rem 2rem; text-align: center; backdrop-filter: blur(20px) !important;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">📦</div>
        <h3 style="color: #C0BEC6 !important; font-size: 1.3rem; margin-bottom: 1rem; font-weight: 500;">Active Batches</h3>
        <div style="font-size: 3.8rem; font-weight: 900; color: #0984C0 !important; text-shadow: 0 0 20px rgba(9,132,192,0.6) !important;">127</div>
        <p style="color: #AAA7B0 !important; font-size: 1.1rem;">FDA Compliant</p>
      </div>
      
      <div style="background: rgba(255,213,0,0.15) !important; border: 2px solid #FFD700 !important; border-radius: 1.5rem; padding: 3rem 2rem; text-align: center; backdrop-filter: blur(20px) !important;">
        <div style="font-size: 4rem; margin-bottom: 1rem;">💰</div>
        <h3 style="color: #C0BEC6 !important; font-size: 1.3rem; margin-bottom: 1rem; font-weight: 500;">Monthly Revenue</h3>
        <div style="font-size: 3.8rem; font-weight: 900; color: #FFD700 !important; text-shadow: 0 0 25px rgba(255,213,0,0.8) !important;">$12K</div>
        <p style="color: #D4AF37 !important; font-size: 1.1rem; font-weight: 600;">Phase 14 Growth</p>
      </div>
    </div>
    
    <div style="text-align: center; margin-top: 4rem; padding: 2rem; background: rgba(15,23,42,0.6) !important; border-radius: 1.5rem; border: 1px solid rgba(9,132,192,0.3) !important;">
      <p style="color: #C0BEC6 !important; font-size: 1.1rem;">🛰️ Solid Stack • Rails 8.1 • 24/7 GPS Tracking • FDA Compliant</p>
    </div>
  </div>
</body>
</html>
    HTML
  }
end
