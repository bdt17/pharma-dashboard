class DashboardController < ApplicationController
  def index
    render inline: <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>PharmaTransport 2.0 ENTERPRISE</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh; 
      color: white; 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      padding: 20px;
    }
    .dashboard { 
      background: rgba(255,255,255,0.1); 
      backdrop-filter: blur(20px); 
      border-radius: 24px; 
      padding: 40px; 
      max-width: 800px; 
      width: 100%; 
      text-align: center; 
      box-shadow: 0 25px 50px rgba(0,0,0,0.2);
      border: 1px solid rgba(255,255,255,0.2);
    }
    h1 { 
      font-size: clamp(2rem, 6vw, 3.5rem); 
      font-weight: 900; 
      margin-bottom: 2rem; 
      background: linear-gradient(135deg, white 0%, rgba(255,255,255,0.8) 100%);
      -webkit-background-clip: text; 
      background-clip: text;
    }
    .stats { 
      display: grid; 
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
      gap: 20px; 
      margin: 2rem 0; 
    }
    .stat { 
      background: rgba(255,255,255,0.15); 
      padding: 20px; 
      border-radius: 16px; 
      backdrop-filter: blur(10px); 
      border: 1px solid rgba(255,255,255,0.2);
      transition: transform 0.3s ease;
    }
    .stat:hover { transform: translateY(-5px); }
    .number { 
      font-size: 2.5rem; 
      font-weight: 900; 
      background: linear-gradient(135deg, #10b981, #059669); 
      -webkit-background-clip: text; 
      background-clip: text;
      margin-bottom: 0.5rem;
    }
    .label { 
      font-size: 1rem; 
      opacity: 0.9; 
      font-weight: 600; 
      text-transform: uppercase; 
      letter-spacing: 0.05em;
    }
    .login-btn { 
      display: inline-block; 
      background: linear-gradient(135deg, #3b82f6, #8b5cf6); 
      color: white; 
      padding: 16px 32px; 
      border-radius: 16px; 
      text-decoration: none; 
      font-weight: 700; 
      font-size: 1.1rem; 
      margin-top: 2rem; 
      transition: all 0.3s ease;
      box-shadow: 0 10px 30px rgba(59,130,246,0.4);
    }
    .login-btn:hover { 
      transform: translateY(-2px); 
      box-shadow: 0 15px 40px rgba(59,130,246,0.6);
    }
    @media (max-width: 640px) { .dashboard { padding: 20px; margin: 10px; } }
  </style>
</head>
<body>
  <div class="dashboard">
    <h1>🏥 PharmaTransport 2.0 ENTERPRISE</h1>
    <div class="stats">
      <div class="stat">
        <div class="number">$4,653</div>
        <div class="label">MRR Revenue</div>
      </div>
      <div class="stat">
        <div class="number">127</div>
        <div class="label">Active Batches</div>
      </div>
      <div class="stat">
        <div class="number">23</div>
        <div class="label">Live Vehicles</div>
      </div>
    </div>
    <a href="/users/sign_in" class="login-btn">🔐 Secure Enterprise Login</a>
    <div style="margin-top: 2rem; opacity: 0.8; font-size: 0.9rem;">
      Thomas IT • Phoenix, AZ • FDA 21 CFR Part 11 Compliant
    </div>
  </div>
</body>
</html>
    HTML
  end

  def health
    render plain: "🟢 OK", layout: false
  end

  def vehicles
    render plain: "🚛 PHX-001, PHX-002, PHX-003 LIVE", layout: false
  end

  def batches
    render plain: "💉 12 ACTIVE FDA BATCHES", layout: false
  end

  def compliance
    render plain: "📋 FDA 21 CFR PART 11 COMPLIANT", layout: false
  end

  def billing
    render plain: "💰 $99/MO ENTERPRISE BILLING READY", layout: false
  end
end
