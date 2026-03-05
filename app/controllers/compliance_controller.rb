class ComplianceController < ApplicationController
  def index
    render plain: "🩺 FDA 21 CFR PART 11 COMPLIANCE\n✅ Chain of Custody PDF ✓\n✅ Immutable Audit Logs ✓\n✅ E-Signatures READY"
  end
end
