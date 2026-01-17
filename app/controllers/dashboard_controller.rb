class DashboardController < ApplicationController
  def index
    render inline: <<-HTML
<!DOCTYPE html>
<html style="background:#FFFFFF;color:#565759">
<head>
  <title>Pharma Transport Dashboard</title>
  <meta name="viewport" content="width=device-width">
  <style>
    * {margin:0;padding:0;box-sizing:border-box}
    body {background:#FFFFFF !important;color:#565759 !important;font-family:Arial,sans-serif;line-height:1.6}
    .header {background:#0984C0 !important;color:white !important;padding:2rem;box-shadow:0 4px 20px rgba(0,0,0,0.1)}
    .nav a {color:white !important;padding:1rem 2rem !important;text-decoration:none !important;background:rgba(255,255,255,0.2) !important;margin:0 0.5rem;border-radius:8px !important;display:inline-block !important}
    .nav a:hover {background:rgba(255,255,255,0.4) !important}
    .container {max-width:1200px;margin:0 auto;padding:3rem 2rem}
    .metrics {display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:2rem;margin:3rem 0}
    .card {background:#FFFFFF !important;border:2px solid #AAA7B0 !important;padding:3rem 2rem !important;border-radius:16px !important;box-shadow:0 10px 40px rgba(0,0,0,0.1) !important;text-align:center !important}
    .card:hover {box-shadow:0 20px 60px rgba(0,0,0,0.2) !important;transform:translateY(-10px) !important}
    .metric-label {color:#565759 !important;font-size:1.2rem !important;font-weight:bold !important;margin-bottom:1rem !important;text-transform:uppercase !important}
    .metric-number {font-size:4.5rem !important;font-weight:900 !important;color:#0984C0 !important;margin-bottom:0.5rem !important}
    .metric-subtitle {color:#AAA7B0 !important;font-size:1rem !important}
    .hero-title {color:#0984C0 !important;font-size:3.5rem !important;font-weight:900 !important;margin-bottom:1rem !important;text-align:center !important}
    .hero-subtitle {color:#565759 !important;font-size:1.4rem !important;text-align:center !important;max-width:600px;margin:0 auto}
    .btn {background:#0984C0 !important;color:white !important;padding:1.5rem 3rem !important;border:none !important;border-radius:12px !important;font-size:1.3rem !important;font-weight:700 !important;text-decoration:none !important;display:inline-block !important;box-shadow:0 8px 32px rgba(9,132,192,0.4) !important}
    .btn:hover {background:#60BDD1 !important;transform:translateY(-4px) !important;box-shadow:0 16px 48px rgba(9,132,192,0.6) !important}
  </style>
</head>
<body>
  <header class="header">
    <div class="container">
      <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap">
        <h1 style="margin:0;font-size:2.5rem;font-weight:800">Pharma Transport</h1>
        <nav style="display:flex;flex-wrap:wrap">
          <a href="/" class="nav a">Dashboard</a>
          <a href="/vehicles" class="nav a">Vehicles</a>
          <a href="/batches" class="nav a">Batches</a>
          <a href="/alerts" class="nav a">Alerts</a>
          <a href="/revenue" class="nav a">Revenue</a>
          <a href="/drivers" class="nav a">Drivers</a>
        </nav>
      </div>
    </div>
  </header>
  
  <div class="container">
    <div style="text-align:center;margin-bottom:4rem">
      <h1 class="hero-title">Dashboard</h1>
      <p class="hero-subtitle">Phase 14 - GPS Tracking & FDA Compliance Platform</p>
    </div>
    
    <div class="metrics">
      <div class="card">
        <div class="metric-label">Live Vehicles</div>
        <div class="metric-number">24</div>
        <div class="metric-subtitle">Phoenix Metro Area</div>
      </div>
      <div class="card">
        <div class="metric-label">Active Batches</div>
        <div class="metric-number">127</div>
        <div class="metric-subtitle">2-8°C Maintained</div>
      </div>
      <div class="card">
        <div class="metric-label">Active Alerts</div>
        <div class="metric-number">3</div>
        <div class="metric-subtitle">Temperature Deviations</div>
      </div>
      <div class="card">
        <div class="metric-label">Monthly Revenue</div>
        <div class="metric-number">$12K</div>
        <div class="metric-subtitle">January 2026</div>
      </div>
    </div>
    
    <div style="text-align:center;margin-top:4rem">
      <a href="/vehicles" class="btn">View All Vehicles</a>
    </div>
  </div>
</body>
</html>
    HTML
  end
end
