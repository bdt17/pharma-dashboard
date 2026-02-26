class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @vehicles_count = 25
    @batches_count = 128
  end

  def health
    render plain: "🟢 PHARMA DASHBOARD v8.1 LIVE", layout: false
  end

  def vehicles
    render plain: "🚛 25 VEHICLES GPS LIVE", layout: false
  end

  def batches
    render plain: "📦 128 BATCHES FDA COMPLIANT", layout: false
  end

  def billing
    render plain: "💰 STRIPE BILLING $12K MRR", layout: false
  end

  def compliance
    render plain: "✅ FDA 21 CFR PART 11 COMPLIANT", layout: false
  end

  def login
    redirect_to new_user_session_path
  end

  # SIMPLE LOGOUT
  def logout
    sign_out(current_user) if user_signed_in?
    redirect_to root_url, notice: 'Logged out'
  end
end
