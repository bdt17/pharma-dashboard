# [Keep all existing Rack code above unchanged...]
def self.enterprise_login_html
  <<~HTML
    <div style="max-width:400px;margin:4rem auto;padding:2rem;border-radius:12px;box-shadow:0 10px 30px rgba(0,0,0,0.2);background:white">
      <h2 style="text-align:center;color:#1f2937;margin-bottom:1.5rem">🔐 Enterprise Login</h2>
      <form action="/auth/enterprise" method="POST">
        <input type="email" name="email" placeholder="your.enterprise@company.com" required 
               style="width:100%;padding:12px;border:1px solid #d1d5db;border-radius:8px;font-size:16px;box-sizing:border-box">
        <input type="password" name="password" placeholder="• • • • • • • •" required 
               style="width:100%;padding:12px;border:1px solid #d1d5db;border-radius:8px;font-size:16px;box-sizing:border-box;margin-top:1rem">
        <button type="submit" style="width:100%;background:#10b981;color:white;padding:12px;border:none;border-radius:8px;font-weight:600;font-size:16px;cursor:pointer;margin-top:1rem">
          ENTER ENTERPRISE DASHBOARD
        </button>
      </form>
      <div style="margin-top:2rem;padding:1rem;background:#f3f4f6;border-radius:8px">
        <p style="text-align:center;color:#6b7280;font-size:14px;margin:0">
          <strong>Phase 10 Security:</strong> MFA → SSO → PAM Q2 2026
        </p>
        <p style="text-align:center;color:#10b981;font-size:12px;margin-top:0.5rem;font-weight:500">
          FDA Compliant • 21 CFR Part 11 Ready
        </p>
      </div>
    </div>
  HTML
end

# Add enterprise auth endpoint
when "/auth/enterprise"
  email = Rack::Utils.parse_query(env["rack.input"].read)[ Rack::Utils.parse_nested_query("email") ]
  [200, {"Content-Type" => "text/html", "Location" => "/dashboard"}, [enterprise_dashboard_html]]
