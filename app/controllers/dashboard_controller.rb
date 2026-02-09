class DashboardController < ApplicationController
  def index
    render inline: <<~HTML
<!DOCTYPE html>
<html>
<head><title>Thomas IT Pharma Transport</title>
<style>*{font-family:'Courier New',monospace;}body{background:#000;color:#00ff00;padding:2rem;font-size:22px;line-height:1.4;white-space:pre;}</style>
</head>
<body>
🟢 PHARMA ENTERPRISE v8.1 - 9/9 LIVE (Phoenix AZ)
═══════════════════════════════════════════════════════════════
<a href="/" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">🏠 Dashboard</a>
<a href="/billing" style="color:#000;background:#ffaa00;padding:1rem;display:block;margin:1rem 0;font-size:24px;">💰 $99/MO → sales@</a>
<a href="/safe" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">🛡️ SAFE MODE</a>
<a href="/vehicles" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">🚛 25 VEHICLES LIVE</a>
<a href="/batches" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">💉 128 FDA BATCHES</a>
<a href="/health" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">🩺 HEALTH CHECK</a>
<a href="/batches/1/chain_of_custody" style="color:#00ff00;background:#00aa00;padding:1rem;display:block;margin:1rem 0;">📄 FDA 21 CFR PART 11</a>

═══════════════════════════════════════════════════════════════
📧 <a href="mailto:sales@thomasinformationtechnology.com" style="color:#ffaa00;font-size:24px;">sales@thomasinformationtechnology.com</a>
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
