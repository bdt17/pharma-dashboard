# config.ru - Pharma Transport Dashboard Phase 10 (Production Frozen)
# Render.com Rack app with landing page + Rails routes
# Thomas IT • Phoenix, AZ • March 2026 • $5M ARR Trajectory

require 'rack'
require 'rails'
require 'action_controller/railtie'

# Load Rails app
ENV['RACK_ENV'] ||= 'production'
require_relative 'config/environment'

# Landing page HTML method (with Enterprise Login button)
def self.thomas_it_landing_html
  <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Pharma Transport Dashboard</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color: white; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
    .container { text-align: center; max-width: 800px; padding: 2rem; }
    .logo { font-size: 3.5rem; font-weight: 800; background: linear-gradient(45deg, #3b82f6, #10b981); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 1.5rem; }
    .tagline { font-size: 1.4rem; margin-bottom: 2rem; opacity: 0.9; }
    .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; margin: 3rem 0; }
    .feature { background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 16px; backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2); }
    .feature h3 { font-size: 1.3rem; margin-bottom: 0.5rem; color: #10b981; }
    .btn-login { position: absolute; right: 2rem; top: 2rem; padding: 12px 24px; background: #0984C0; color: #FFFFFF; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 1rem; box-shadow: 0 4px 14px rgba(9,132,192,0.4); transition: all 0.3s ease; }
    .btn-login:hover { background: #0e73b3; transform: translateY(-2px); box-shadow: 0 6px 20px rgba(9,132,192,0.5); }
    .stats { display: flex; justify-content: center; gap: 3rem; margin: 2rem 0; font-size: 1.2rem; }
    .stat { text-align: center; }
    .stat-number { font-size: 2.5rem; font-weight: 800; color: #10b981; }
    footer { position: absolute; bottom: 2rem; left: 50%; transform: translateX(-50%); opacity: 0.7; font-size: 0.9rem; }
  </style>
</head>
<body>
  <a href="/users/sign_in" class="btn-login">Enterprise Login</a>
  <div class="container">
    <div class="logo">Pharma Transport</div>
    <p class="tagline">Live Fleet • Batches • Health Dashboard</p>
    
    <div class="stats">
      <div class="stat">
        <div class="stat-number">42</div>
        <div>Queclink GV55 Devices</div>
      </div>
      <div class="stat">
        <div class="stat-number">22/22</div>
        <div>Endpoints Operational</div>
      </div>
      <div class="stat">
        <div class="stat-number">FDA</div>
        <div>Compliant</div>
      </div>
    </div>

    <div class="features">
      <div class="feature">
        <h3>🚚 Live Fleet Tracking</h3>
        <p>GPS monitoring for pharma transport compliance</p>
      </div>
      <div class="feature">
        <h3>📄 Chain of Custody</h3>
        <p>21 CFR Part 11 digital signatures & audit trails</p>
      </div>
      <div class="feature">
        <h3>✅ Health Status</h3>
        <p>Real-time endpoint monitoring & alerts</p>
      </div>
    </div>

    <footer>
      Phase 10 Enterprise SaaS • © 2026 Thomas IT. Phoenix, AZ
    </footer>
  </div>
</body>
</html>
HTML
end

# Rack app routes
class PharmaApp
  def self.call(env)
    req = Rack::Request.new(env)
    
    case req.path
    when "/"
      [200, {'Content-Type' => 'text/html'}, [thomas_it_landing_html]]
    when "/gps"
      Rails.application.call(env)
    else
      Rails.application.call(env)
    end
  end
end

run PharmaApp
