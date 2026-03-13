class HomeController < ApplicationController
  def index
  end
  def vehicles
    render 'index'  # Reuse dashboard view for now
  end
  def gps
    render 'index'
  end
end

  def login_stub
    render layout: 'application' do |format|
      format.html {
        '<div style="text-align:center;padding:4rem;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border-radius:20px;margin:2rem">
          <h1 style="font-size:3rem;margin-bottom:1rem">🔐 ENTERPRISE LOGIN</h1>
          <p style="font-size:1.3rem;margin-bottom:2rem">Phase 10 SaaS • FDA Compliant</p>
          <a href="/enterprise/dashboard" style="background:#10b981;color:white;padding:1.2rem 3rem;border-radius:12px;text-decoration:none;font-weight:600;font-size:1.1rem">→ ENTER DASHBOARD (Demo)</a>
          <p style="margin-top:2rem;color:#e2e8f0">Full Multi-Tenant Auth → Q2 2026</p>
        </div>'
      }
    end
  end
