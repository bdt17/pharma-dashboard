class DashboardController < ApplicationController
  def index
    @phase = "14 - Autonomous + AI + Marketplace"
    @vehicles = 24
    @batches = 127
    @alerts = 3
    @revenue_today = 1_245_000
    @endpoints = {
      gps: "POST /api/gps",
      waymo: "POST /api/waymo/123",
      ai: "POST /api/ai/predict-excursion",
      marketplace: "POST /api/marketplace/bid"
    }
  end

  def pfizer
    @client = "Pfizer"
    @batch = "PFIZER-INSULIN"
    @revenue = "$47B FDA Supply Chain"
  end
end
