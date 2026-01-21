class HomepageController < ApplicationController
  def index
    render layout: false, html: <<~'HTML'
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:system-ui;background:#0a0a0a;color:white;min-height:100vh;padding:20px;}
    table{border-collapse:collapse;width:100%;max-width:1000px;margin:0 auto;background:#1e3c72;border-radius:12px;overflow:hidden;box-shadow:0 20px 40px rgba(0,0,0,0.5);}
    td{padding:25px;text-align:center;vertical-align:top;}
    .header{padding:30px;font-size:28px;font-weight:bold;background:#0f2440;}
    .stats td{background:#2a4a7a;width:33%;}
    .num{font-size:48px;font-weight:900;display:block;margin-bottom:10px;}
    .g{color:#00ff88;}
    .o{color:#ffaa00;}
    .r{color:#ff4444;}
    h3{font-size:22px;margin:0 0 15px;}
    .eta{color:#00ff88;font-weight:bold;}
    .btn{display:inline-block;padding:18px 40px;background:#00ff88;color:black;text-decoration:none;border-radius:10px;font-size:20px;font-weight:bold;}
  </style>
</head>
<body>
  <table>
    <tr><td colspan="3" class="header">Pharma Transport</td></tr>
    <tr class="stats">
      <td><span class="num g">127</span>Active Batches</td>
      <td><span class="num o">24</span>Live Vehicles</td>
      <td><span class="num r">$12K</span>Monthly Revenue</td>
    </tr>
    <tr>
      <td style="width:50%;">
        <h3>🚛 Vehicle Fleet</h3>
        PHX-001 → Scottsdale <span class="eta">(ETA 8min)</span><br>
        PHX-002 → Tempe <span class="eta">(ETA 12min)</span><br>
        PHX-003 → Mesa <span class="eta">(ETA 15min)</span><br>
        PHX-004 → Glendale <span class="eta">(ETA 9min)</span>
      </td>
      <td colspan="2">
        <h3>📦 Top Routes</h3>
        CVS → Patient Home <span class="eta">(42%)</span><br>
        Walgreens → Patient Home <span class="eta">(28%)</span><br>
        Patient Home → Pharmacy <span class="eta">(18%)</span><br>
        Pharmacy → Hospital <span class="eta">(12%)</span>
      </td>
    </tr>
    <tr><td colspan="3" style="padding:30px;text-align:center;"><a href="#" class="btn">🗺️ Fullscreen Map</a></td></tr>
  </table>
</body>
</html>
HTML
  end
  
  def revenue_test
    render plain: "FDA REVENUE LIVE ✓", status: 200
  end
end
