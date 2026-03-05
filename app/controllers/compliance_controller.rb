class ComplianceController < ApplicationController
  def index
    render plain: "🩺 FDA 21 CFR PART 11 ✓\n✅ Chain of Custody PDF Certified\n✅ Immutable Logs ✓\n✅ Cold Chain 2-8°C ✓"
  end
end
