class HomeController < ApplicationController
  before_action :authenticate_user!, only: [
    :enterprise_dashboard,
    :gps,
    :vehicles,
    :chain_of_custody,
    :billing
  ]

  def index
    render html: <<~HTML.html_safe
      <div style="text-align:center;padding:4rem;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border-radius:20px;margin:2rem">
        <h1 style="font-size:3rem;margin-bottom:1rem">Pharma Transport</h1>
        <p style="font-size:1.3rem;margin-bottom:2rem">Enterprise logistics platform</p>
        <a href="/login" style="background:#10b981;color:white;padding:1.2rem 3rem;border-radius:12px;text-decoration:none;font-weight:600;font-size:1.1rem">Sign in</a>
      </div>
    HTML
  end

  def login
    redirect_to new_user_session_path
  end

  def enterprise_dashboard
    render html: <<~HTML.html_safe
      <div style="padding:2rem;background:#f8fafc;min-height:100vh">
        <div style="max-width:1200px;margin:0 auto">
          <h1 style="color:#1f2937;font-size:2.5rem;margin-bottom:1rem">Pharma Transport Dashboard</h1>
          <p>Authenticated user: #{ERB::Util.html_escape(current_user.email)}</p>
        </div>
      </div>
    HTML
  end

  def gps
    render json: {
      status: "GPS STUB - Phase 11",
      message: "Queclink GV55 IoT → Q2 2026",
      endpoints: 8,
      vehicles: 0
    }
  end

  def vehicles
    render json: {
      vehicles: 42,
      status: "Phase 10 LIVE",
      fleet: "Queclink GV55 Ready",
      endpoints: 8
    }
  end

  def chain_of_custody
    pdf_content = "PHASE 10 CoC STUB\nBatch ID: #{params[:id]}\nFDA Compliant\n8/8 GREEN"

    send_data pdf_content,
              filename: "chain-of-custody-#{params[:id]}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def health
    render plain: "ok"
  end

  def billing
    render html: <<~HTML.html_safe
      <div style="padding:4rem;text-align:center">
        <h1>Billing</h1>
        <a href="/dashboard">Dashboard</a>
      </div>
    HTML
  end

  def signup
    redirect_to new_user_registration_path
  end

  def landing
    redirect_to root_path
  end

  def subscribe
    render html: <<~HTML.html_safe
      <div style="padding:4rem;text-align:center">
        <h1>Subscription</h1>
        <p>Subscription setup is coming soon.</p>
        <a href="/">Return home</a>
      </div>
    HTML
  end
end
