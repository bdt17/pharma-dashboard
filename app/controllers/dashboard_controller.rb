class DashboardController < ApplicationController
  def index
    render plain: "🏠 PHARMA TRANSPORT DASHBOARD v16.1 - LIVE", layout: false
  end

  def health
    render plain: "🟢 OK", layout: false
  end

  def vehicles
    render plain: "🚛 PHX-001, PHX-002, PHX-003 LIVE", layout: false
  end

  def batches
    render plain: "💉 12 ACTIVE FDA BATCHES", layout: false
  end

  def compliance
    render plain: "📋 FDA 21 CFR PART 11 COMPLIANT", layout: false
  end

  def billing
    render plain: "💰 $99/MO ENTERPRISE BILLING READY", layout: false
  end
end
