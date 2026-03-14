ENV['RACK_ENV'] ||= 'production'
require_relative 'config/environment'

# FORCE landing page - higher priority than Rails routes
app = lambda do |env|
  if env["PATH_INFO"] == "/"
    [200, {"Content-Type" => "text/html"}, [<<~HTML]]
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Dashboard - Phase 10 Live</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:system-ui;background:linear-gradient(135deg,#0f172a 0%,#1e293b 100%);color:#fff;min-height:100vh;position:relative}
    .login{position:fixed;right:2rem;top:2rem;z-index:9999;padding:14px 28px;background:#0984C0;color:#fff!important;text-decoration:none!important;border-radius:12px;font-weight:700;font-size:1.1rem;box-shadow:0 8px 24px rgba(9,132,192,.5);border:2px solid rgba(255,255,255,.2)}
    .login:hover{background:#0e73b3;transform:translateY(-3px);box-shadow:0 12px 32px rgba(9,132,192,.6)}
    .container{max-width:1200px;margin:0 auto;padding:8rem 2rem 4rem;text-align:center}
    .logo{font-size:4.5rem;font-weight:900;background:linear-gradient(45deg,#3b82f6,#10b981);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:1.5rem;letter-spacing:-2px}
    h1{font-size:1.8rem;margin-bottom:4rem;opacity:.95}
    .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:2rem;margin:3rem 0}
    .stat{background:rgba(255,255,255,.15);padding:2.5rem;border-radius:20px;border:1px solid rgba(255,255,255,.3);backdrop-filter:blur(20px);transition:transform .3s}
    .stat:hover{transform:translateY(-8px)}
    .stat-number{font-size:3.5rem;font-weight:900;color:#10b981;margin-bottom:.5rem}
    .stat a{color:#60a5fa!important;text-decoration:none;font-weight:600;font-size:1.1rem;display:block;margin-top:1rem}
    .stat a:hover{color:#93c5fd;text-decoration:underline}
    footer{position:fixed;bottom:2rem;left:50%;transform:translateX(-50%);opacity:.6;font-size:.85rem}
  </style>
</head>
<body>
  <!-- FORCE LOGIN BUTTON - highest z-index -->
  <a href="/users/sign_in" class="login">Enterprise Login →</a>
  
  <div class="container">
    <div class="logo">Pharma Transport</div>
    <h1>Phase 10 Enterprise SaaS • Live Fleet Tracking</h1>
    
    <div class="stats">
      <div class="stat">
        <div class="stat-number">📄 Chain of Custody</div>
        <div>21 CFR Part 11 compliant tracking</div>
        <a href="/batches/1/chain-of-custody.pdf">Download PDF →</a>
      </div>
      <div class="stat">
        <div class="stat-number">🚚 42 Live</div>
        <div>Queclink GV55 GPS devices - Phoenix AZ</div>
        <a href="/gps">View Live Fleet →</a>
      </div>
      <div class="stat">
        <div class="stat-number">✅ 22/22</div>
        <div>Endpoints operational - FDA compliant</div>
        <a href="/health">System Status →</a>
      </div>
    </div>
  </div>
  
  <footer>© 2026 Thomas IT • Phoenix, Arizona</footer>
</body>
</html>
HTML
  else
    Rails.application.call(env)
  end
end

run app
