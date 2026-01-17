def index
  @phase = "14 - Autonomous + AI + Marketplace"
  @endpoints = {
    gps: "POST /api/gps",
    waymo: "POST /api/waymo/123",
    ai: "POST /api/ai/predict-excursion",
    marketplace: "POST /api/marketplace/bid"
  }
  
  # Dashboard metrics (your template needs these)
  @vehicles = 24
  @batches = 127
  @alerts = 3
  @revenue_today = 1_245_000  # $1.24M
end
