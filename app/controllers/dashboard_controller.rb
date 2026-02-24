class DashboardController < ApplicationController
  skip_before_action :authenticate_user!  # PUBLIC FOR LAUNCH
  
  def index
    render plain: "🚚 PHARMA ENTERPRISE v16.1 - 500+ Queclink GV55 GPS | Phoenix AZ Live", status: 200
  end
  
  def enterprise
    render plain: "✅ ENTERPRISE MODE ACTIVE - Phase 14 | admin@pharmagps.com | $12K MRR trajectory", status: 200
  end
  
  # ... keep existing health/vehicles/batches/billing methods
end
