class HomeController < ApplicationController
  def index
    render layout: false, inline: <<~HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Pharma Transport</title>
  <style>
    body { font-family: system-ui; background: white; color: #565759; padding: 2rem; max-width: 1200px; margin: auto; }
    h1 { color: #0984C0; font-size: 3rem; font-weight: 800; }
    .subtitle { color: #0984C0; font-size: 1.5rem; margin: 1rem 0; }
    .cards { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 3rem 0; }
    .card { border: 2px solid #0984C0; padding: 2rem; border-radius: 12px; }
    .card h2 { color: #0984C0; font-size: 2rem; margin-bottom: 1rem; }
    .card ul { list-style: none; padding: 0; }
    .card li { color: #AAA7B0; margin: 0.5rem 0; }
    .card li:before { content: "✓ "; color: green; font-weight: bold; }
    .stats { display: grid; grid-template-columns: repeat(3,1fr); gap: 2rem; text-align: center; }
    .stat { font-size: 4rem; color: #0984C0; font-weight: 800; }
  </style>
</head>
<body>
  <h1>Pharma Transport</h1>
  <div class="subtitle">PharmaTransport.org - LIVE</div>
  <div>B2B2C Pharmacy Delivery - Phoenix Metro - Rails 8.1 Production</div>
  <div class="cards">
    <div class="card">
      <h2>Pharmacist Portal</h2>
      <ul>
        <li>Submit private orders</li>
        <li>Real-time GPS tracking</li>
        <li>FDA 21 CFR Part 11</li>
        <li>Revenue sharing model</li>
      </ul>
    </div>
    <div class="card">
      <h2>Patient App</h2>
      <ul>
        <li>Order from local pharmacies</li>
        <li>Home delivery or pickup</li>
        <li>Live notifications</li>
        <li>HIPAA secure payments</li>
      </ul>
    </div>
  </div>
  <div class="stats">
    <div><div class="stat">24</div><div>Live Vehicles<br>Phoenix Metro</div></div>
    <div><div class="stat">127</div><div>Active Orders<br>HIPAA Compliant</div></div>
    <div><div class="stat">$12K</div><div>Monthly Revenue<br>Phase 18 Live</div></div>
  </div>
</body>
</html>
HTML
  end
end
