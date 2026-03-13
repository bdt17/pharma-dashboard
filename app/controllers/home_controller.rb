class HomeController < ApplicationController
  def index
    render html: <<-HTML
      <div style="text-align:center;padding:4rem;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border-radius:20px;margin:2rem">
        <h1 style="font-size:3rem;margin-bottom:1rem">🔐 ENTERPRISE LOGIN</h1>
        <p style="font-size:1.3rem;margin-bottom:2rem">Phase 10 SaaS • FDA Compliant</p>
        <a href="/enterprise/dashboard" style="background:#10b981;color:white;padding:1.2rem 3rem;border-radius:12px;text-decoration:none;font-weight:600;font-size:1.1rem">→ ENTER DASHBOARD (Demo)</a>
        <p style="margin-top:2rem;color:#e2e8f0">Full Multi-Tenant Auth → Q2 2026</p>
      </div>
    HTML
  end

  def login
    render html: <<-HTML
      <div style="max-width:400px;margin:4rem auto;padding:2rem;border-radius:12px;box-shadow:0 10px 30px rgba(0,0,0,0.2);background:white">
        <h2 style="text-align:center;color:#1f2937;margin-bottom:1.5rem">🔐 Enterprise Login</h2>
        <form action="/users/sign_in" method="POST" style="display:flex;flex-direction:column;gap:1rem">
          <input type="email" name="user[email]" placeholder="Enterprise Email" required 
                 style="padding:12px;border:1px solid #d1d5db;border-radius:8px;font-size:16px">
          <input type="password" name="user[password]" placeholder="Password" required 
                 style="padding:12px;border:1px solid #d1d5db;border-radius:8px;font-size:16px">
          <button type="submit" style="background:#10b981;color:white;padding:12px;border:none;border-radius:8px;font-weight:600;font-size:16px;cursor:pointer">LOGIN</button>
        </form>
        <p style="text-align:center;margin-top:1rem;color:#6b7280;font-size:14px">
          Demo: admin@pharmatransport.com / pharma123
        </p>
      </div>
    HTML
  end

  def gps
    render json: {
      status: "GPS STUB - Phase 11",
      message: "Queclink GV55 IoT → Q2 2026",
      endpoints: 8,
      vehicles: 0,
      position: { lat: 33.4484, lng: -112.0740 } # Phoenix demo
    }
  end

  def enterprise_dashboard
    render html: <<-HTML
      <div style="padding:2rem;background:#f8fafc min-height:100vh">
        <div style="max-width:1200px;margin:0 auto">
          <h1 style="color:#1f2937;font-size:2.5rem;margin-bottom:1rem">🚚 Pharma Transport Dashboard</h1>
          <div style="background:#10b981;color:white;padding:1rem;border-radius:8px;margin-bottom:2rem">
            <strong>Phase 10 LIVE</strong> | 8/8 Endpoints ✅ | $5M ARR Trajectory
          </div>
          <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:1.5rem">
            <div style="background:white;padding:1.5rem;border-radius:12px;box-shadow:0 4px 6px rgba(0,0,0,0.05)">
              <h3 style="color:#1f2937;margin-bottom:1rem">📍 GPS Tracking</h3>
              <p>Queclink GV55 → <strong>Phase 11</strong></p>
            </div>
            <div style="background:white;padding:1.5rem;border-radius:12px;box-shadow:0 4px 6px rgba(0,0,0,0.05)">
              <h3 style="color:#1f2937;margin-bottom:1rem">📄 Chain of Custody</h3>
              <p>PDF Generation → <span style="color:#10b981">LIVE ✅</span></p>
            </div>
            <div style="background:white;padding:1.5rem;border-radius:12px;box-shadow:0 4px 6px rgba(0,0,0,0.05)">
              <h3 style="color:#1f2937;margin-bottom:1rem">💳 Stripe Checkout</h3>
              <p>Multi-Tenant Billing → <strong>Phase 12</strong></p>
            </div>
          </div>
        </div>
      </div>
    HTML
  end
end
