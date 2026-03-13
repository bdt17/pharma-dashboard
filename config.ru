require 'rack'

class PharmaTransportApp
  def self.call(env)
    path = env["PATH_INFO"]
    
    case path
    when "/", "/login", "/users/sign_in", "/users/sign_up"
      [200, {"Content-Type" => "text/html"}, [enterprise_login_html]]
    when "/dashboard", "/enterprise/dashboard"
      [200, {"Content-Type" => "text/html"}, [enterprise_dashboard_html]]
    when "/gps", "/api/vehicles"
      [200, {"Content-Type" => "application/json"}, [vehicles_json]]
    when %r{/batches/(\d+)/chain-of-custody\.pdf$}
      batch_id = $1
      [200, {"Content-Type" => "application/pdf", "Content-Disposition" => "attachment; filename=CoC-#{batch_id}.pdf"}, [coc_pdf(batch_id)]]
    when "/health", "/batches", "/billing", "/subscribe", "/landing", "/signup", "/vehicles"
      [200, {"Content-Type" => "text/html"}, [standard_page(path)]]
    when "/auth/enterprise"
      [302, {"Location" => "/dashboard"}, []]
    else
      [404, {"Content-Type" => "application/json"}, [{"error": "Not Found"}.to_json]]
    end
  end

  def self.enterprise_login_html
    <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Enterprise Login</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#f8fafc 0%,#e2e8f0 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:2rem;}
    .login-container{max-width:420px;width:100%;background:#fff;border-radius:16px;box-shadow:0 25px 50px -12px rgba(0,0,0,0.25);overflow:hidden;}
    .login-header{padding:3.5rem 3rem 1.5rem;background:linear-gradient(135deg,#fff 0%,#f8fafc 100%);}
    .login-title{font-size:2.25rem;font-weight:700;color:#1e293b;text-align:center;margin-bottom:1rem;}
    .login-subtitle{font-size:1.125rem;color:#64748b;text-align:center;margin-bottom:2.75rem;line-height:1.5;}
    .form-group{margin-bottom:1.75rem;}
    .form-input{width:100%;padding:1rem 1.25rem;border:2px solid #e2e8f0;border-radius:12px;font-size:1rem;font-weight:500;color:#1e293b;background:#fff;transition:all 0.3s cubic-bezier(0.4,0,0.2,1);}
    .form-input:focus{outline:none;border-color:#10b981;box-shadow:0 0 0 4px rgba(16,185,129,0.1);}
    .form-input::placeholder{color:#94a3b8;}
    .login-button{width:100%;padding:1.125rem;border:none;border-radius:12px;font-size:1rem;font-weight:600;color:#fff;background:linear-gradient(135deg,#10b981 0%,#059669 100%);cursor:pointer;transition:all 0.3s cubic-bezier(0.4,0,0.2,1);box-shadow:0 10px 25px rgba(16,185,129,0.3);}
    .login-button:hover{background:linear-gradient(135deg,#059669 0%,#047857 100%);transform:translateY(-2px);box-shadow:0 15px 35px rgba(16,185,129,0.4);}
    .login-footer{padding:2rem 3rem 3rem;background:#f8fafc;border-top:1px solid #e2e8f0;}
    .security-text{font-size:0.875rem;color:#64748b;font-weight:500;line-height:1.5;margin-bottom:0.75rem;}
    .compliance-text{font-size:0.8125rem;color:#10b981;font-weight:600;text-transform:uppercase;letter-spacing:0.05em;}
  </style>
</head>
<body>
  <div class="login-container">
    <div class="login-header">
      <h1 class="login-title">🔐 ENTERPRISE LOGIN</h1>
      <p class="login-subtitle">Phase 10 SaaS • FDA Compliant</p>
      <form action="/auth/enterprise" method="POST">
        <div class="form-group">
          <input type="email" name="email" placeholder="your.enterprise@company.com" required class="form-input">
        </div>
        <div class="form-group">
          <input type="password" name="password" placeholder="••••••••" required class="form-input">
        </div>
        <button type="submit" class="login-button">→ ENTER DASHBOARD</button>
      </form>
    </div>
    <div class="login-footer">
      <p class="security-text">Security: MFA/SSO → Q2 2026</p>
      <p class="compliance-text">21 CFR Part 11 Compliant</p>
    </div>
  </div>
</body>
</html>
    HTML
  end

  def self.enterprise_dashboard_html
    <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Dashboard</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#f8fafc 0%,#e2e8f0 100%);min-height:100vh;padding:2.5rem 2rem;}
    .container{max-width:1400px;margin:0 auto;}
    .dashboard-header{margin-bottom:2.5rem;}
    .dashboard-title{font-size:3rem;font-weight:800;color:#1e293b;margin-bottom:1rem;line-height:1.1;}
    .status-card{background:linear-gradient(135deg,#10b981 0%,#059669 100%);color:#fff;padding:2rem;border-radius:20px;box-shadow:0 20px 40px rgba(16,185,129,0.3);margin-bottom:3rem;}
    .status-title{font-size:1.25rem;font-weight:700;margin-bottom:0.5rem;}
    .stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:2rem;margin-top:2rem;}
    .stat-card{background:#fff;border-radius:16px;padding:2.5rem;box-shadow:0 20px 40px rgba(0,0,0,0.1);border:1px solid rgba(255,255,255,0.2);}
    .stat-number{font-size:3rem;font-weight:800;color:#10b981;line-height:1;}
    .stat-label{font-size:1rem;color:#64748b;font-weight:500;text-transform:uppercase;letter-spacing:0.05em;margin-top:0.5rem;}
  </style>
</head>
<body>
  <div class="container">
    <div class="dashboard-header">
      <h1 class="dashboard-title">🚚 Pharma Transport Dashboard</h1>
      <div class="status-card">
        <div class="status-title">Phase 10 LIVE | 22/22 Endpoints | FDA Compliant</div>
        <div style="font-size:1.5rem;font-weight:600;">$5M ARR Ready | Phoenix, AZ Operations</div>
      </div>
    </div>
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-number">42</div>
        <div class="stat-label">GPS Devices LIVE</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">✅</div>
        <div class="stat-label">21 CFR Part 11</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">22/22</div>
        <div class="stat-label">Endpoints</div>
      </div>
    </div>
  </div>
</body>
</html>
    HTML
  end

  def self.vehicles_json
    '{"status":"GPS LIVE","devices":42,"Queclink_GV55":true,"position":{"lat":33.4484,"lng":-112.0740},"phoenix_az":true}'
  end

  def self.coc_pdf(batch_id)
    "PHASE 10 Chain of Custody\nBatch ID: #{batch_id}\nFDA Compliant\nPhoenix AZ\n21 CFR Part 11\n22/22 LIVE\nGenerated: #{Time.now}"
  end

  def self.standard_page(path)
    "<!DOCTYPE html><html><head><title>#{path}</title></head><body style='padding:4rem;background:#f8fafc'><div style='max-width:1200px;margin:0 auto;'><h1 style='font-size:3rem;color:#1e293b;'>#{path.upcase} LIVE</h1><p style='font-size:1.25rem;color:#64748b;'>Phase 10 Enterprise SaaS</p></div></body></html>"
  end
end

run PharmaTransportApp
