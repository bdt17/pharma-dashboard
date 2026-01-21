class HomepageController < ApplicationController
  def index
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    
    render layout: false, html: <<~HTML
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Dashboard v#{Time.now.strftime('%Y%m%d%H%M')}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    /* Your existing CSS for 3-column dashboard */
    body { font-family: Arial, sans-serif; margin: 20px; }
    .dashboard { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; }
    .card { border: 1px solid #ddd; padding: 20px; border-radius: 8px; }
    .metric { font-size: 2em; font-weight: bold; color: #2563eb; }
  </style>
</head>
<body>
  <div class="dashboard">
    <div class="card">
      <h2>ACTIVE BATCHES</h2>
      <div class="metric">127</div>
    </div>
    <div class="card">
      <h2>LIVE VEHICLES</h2>
      <div class="metric">24</div>
    </div>
    <div class="card">
      <h2>MONTHLY REVENUE</h2>
      <div class="metric">$12K</div>
    </div>
  </div>
</body>
</html>
    HTML
  end
end
