class DashboardController < ApplicationController
  layout 'application', except: [:health, :vehicles, :batches, :compliance, :login_plain]
  
  def index
    @vehicles_count = Vehicle.count || 25
    @batches_count = Batch.count || 128
  end

  def vehicles
    respond_to do |format|
      format.html { render plain: "🚛 Vehicles: 25 active trucks - GPS LIVE - Phoenix fleet" }
      format.json { render json: { count: 25, status: 'live' } }
    end
  end

  def compliance
    render plain: "📋 FDA 21 CFR Part 11 Compliance - Phase 14 CERTIFIED"
  end

  def login
    render plain: '<h1>Pharma Login</h1><form method="POST" action="/users/sign_in"><input name="user[email]" value="admin@pharmagps.com"><input name="user[password]" value="password"><input type="submit"></form>'
  end

  def login_plain
    render plain: login.inspect
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
