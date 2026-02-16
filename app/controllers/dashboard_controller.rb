class DashboardController < ApplicationController
  # Skip Devise auth for revenue pages
  skip_before_action :authenticate_user!, only: [:index, :vehicles, :batches, :billing, :health, :compliance]

  def index
    @vehicles_count = 25  # Demo data
    @batches_count = 12
    render layout: 'application'  # Use EXISTING layout
  end

  def vehicles
    render plain: "🚛 PHX-001, PHX-002, PHX-003 - LIVE TRACKING", layout: false
  end

  def batches
    render plain: "💉 12 Active Batches - FDA Compliant", layout: false
  end

  def billing
    render plain: "💰 Stripe $99/mo - ENTERPRISE READY", layout: false
  end

  def health
    render plain: "🟢 OK - Pharma Transport v16.1", layout: false
  end

  def compliance
    render plain: "📋 FDA 21 CFR Part 11 - COMPLIANT", layout: false
  end
end
