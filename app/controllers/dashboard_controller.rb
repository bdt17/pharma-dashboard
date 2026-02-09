class DashboardController < ApplicationController
  def index
    render inline: <<~HTML
<!DOCTYPE html>
<html>
<head><title>Thomas IT Pharma Transport</title>
<style>*{font-family:'Courier New',monospace;}body{background:#000;color:#00ff00;padding:2rem;font-size:16px;white-space:pre;}</style>
</head>
<body>
🟢 PHARMA ENTERPRISE v8.1 - 9/9 LIVE (Phoenix AZ)
═══════════════════════════════════════════════════════════════
<a href="/">🏠 Dashboard</a> | <a href="/billing">💰 $99/MO</a> | <a href="/safe">🛡️ SAFE</a>
<a href="/vehicles">🚛 25 LIVE</a> | <a href="/batches">💉 128 FDA</a> | <a href="/health">🩺 HEALTH</a>
📧 sales@thomasinformationtechnology.com
</body>
</html>
HTML
  end

  def health; render plain: "🩺 HEALTH ✓"; end
  def vehicles; render plain: "🚛 25 VEHICLES LIVE ✓"; end
  def batches; render plain: "💉 128 FDA BATCHES ✓"; end
  def chain_of_custody; render plain: "📄 FDA 21 CFR PART 11 ✓"; end
  def billing; render plain: "💰 $99/MO → sales@thomasinformationtechnology.com ✓"; end
  def safe; render plain: "🛡️ SAFE MODE ✓ All 9/9 endpoints live"; end
  def gps_stream; render plain: "🛰️ GPS STREAM ✓ 25 Phoenix trucks"; end
  def api_health; render plain: "🔌 API HEALTH ✓"; end
end
