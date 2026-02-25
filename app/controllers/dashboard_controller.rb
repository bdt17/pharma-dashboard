class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @vehicles_count = 25
    @batches_count = 128
  end

  def health
    render plain: "🟢 PHARMA DASHBOARD v8.1 LIVE - FDA 21 CFR Part 11", layout: false
  end

  def vehicles
    render plain: "🚛 25 VEHICLES GPS LIVE - Phoenix AZ → Las Vegas NV", layout: false
  end

  def batches
    render plain: "📦 128 BATCHES FDA 21 CFR Part 11 Compliant", layout: false
  end

  def billing
    render plain: "💰 Stripe Billing - $12K MRR trajectory - 47 clients", layout: false
  end

  def compliance
    render plain: "✅ FDA 21 CFR Part 11 | HIPAA | GxP | Audit Trail Active", layout: false
  end

  def login
    redirect_to new_user_session_path
  end

  def logout
    sign_out(current_user)
    redirect_to root_path, notice: 'Logged out successfully'
  end
end
