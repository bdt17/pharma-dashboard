# config.ru - Pharma Transport Dashboard Phase 10 (SIMPLE LANDING)
# Render Rails + Custom landing page (Rails-safe)

# Load Rails FIRST (production environment)
ENV['RACK_ENV'] ||= 'production'
require_relative 'config/environment'

# Simple landing page lambda
landing_page = lambda do |_env|
  [200, 
   { 'Content-Type' => 'text/html' },
   [<<~HTML
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Dashboard</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif; background: linear-gradient(135deg,#0f172a 0%,#1e293b 100%); color: white; min-height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; }
    .container { text-align: center; max-width: 800px; padding: 2rem; position: relative; }
    .logo { font-size: 3.5rem; font-weight: 800; background: linear-gradient(45deg,#3b82f6,#10b981); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 1.5rem; }
    .btn-login { position: absolute; right: 2rem; top: 2rem; padding: 12px 24px; background: #0984C0; color: #FFFFFF; text-decoration: none; border-radius: 8px; font-weight: 600; box-shadow: 0 4px 14px rgba(9,132,192,0.4); }
    .btn-login:hover { background: #0e73b3; transform: translateY(-2px); }
    .stats { display: flex; justify-content: center; gap: 3rem; margin: 2rem 0; }
    .stat-number { font-size: 2.5rem; font-weight: 800; color: #10b981; }
    footer { position: absolute; bottom: 2rem; left: 50%; transform: translateX(-50%); opacity: 0.7; font-size: 0.9rem; }
  </style>
</head>
<body>
  <div class="container">
    <a href="/users/sign_in" class="btn-login">Enterprise Login</a>
    <div class="logo">Pharma Transport</div>
    <div class="stats">
      <div><div class="stat-number">42</div>Queclink GV55</div>
      <div><div class="stat-number">22/22</div>Endpoints</div>
      <div><div class="stat-number">FDA</div>Compliant</div>
    </div>
    <footer>Phase 10 Enterprise SaaS • © 2026 Thomas IT. Phoenix, AZ</footer>
  </div>
</body>
</html>
HTML
   ]
  ]
end

# Rack::Builder - CORRECT Rails integration
map "/" do
  run landing_page
end

# All other Rails routes (login, dashboard, GPS, etc.)
run Rails.application
