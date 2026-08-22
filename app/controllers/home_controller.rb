class HomeController < ApplicationController
  before_action :authenticate_user!, only: [
    :enterprise_dashboard,
    :gps,
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

  # Real fleet positions for the signed-in user's organization, scoped the
  # same way the API is (VehiclePolicy::Scope) -- this used to render a
  # hardcoded JSON stub claiming "vehicles: 0" regardless of what was
  # actually in the database.
  def gps
    @vehicles = policy_scope(Vehicle).order(:name)
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
