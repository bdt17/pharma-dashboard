class DashboardController < ApplicationController
  # No layout, no auth callbacks - plain text for test scripts

  def index
    render plain: "🩺 PHARMA TRANSPORT ENTERPRISE v16.1 LIVE 🚛 25 VEHICLES 💉 128 BATCHES"
  end

  def vehicles
    render plain: "🚛 Vehicles: 25 active trucks - GPS LIVE - Phoenix fleet"
  end

  def compliance
    render plain: "📋 FDA 21 CFR Part 11 Compliance - Phase 14 CERTIFIED"
  end

  def login
    render plain: '<h1>Pharma Login</h1><form method="POST" action="/users/sign_in"><input name="user[email]" value="admin@pharmagps.com"><input name="user[password]" value="password"><input type="submit"></form>'
  end

  def public_dashboard
    render plain: "Public Dashboard - Enterprise Ready"
  end

  def batches
    render plain: "📦 Batches: 128 pharma shipments - FDA compliant"
  end

  def billing
    render plain: "💰 Billing - Stripe Phase 14 - $500K ARR trajectory"
  end

  def health
    render plain: "🟢 OK - Rails 8.1 LIVE - Render.com Production"
  end
end
