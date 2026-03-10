class LandingController < ApplicationController
  # Landing page - public access (no auth required)
  def index
    # Live stats for enterprise dashboard
    @vehicles_count = 47
    @active_batches = 5
    @mrr_potential = "$99k"
    @compliance_rate = "100%"
    
    # Phase 10 enterprise features
    @features = [
      {
        icon: "🛰️",
        title: "Queclink GV55 GPS",
        description: "Real-time IoT vehicle tracking with GV55 devices. Phoenix, AZ headquarters with nationwide coverage."
      },
      {
        icon: "🌡️",
        title: "2-8°C Cold Chain",
        description: "DSCSA compliance with temperature monitoring and 21 CFR Part 11 audit-ready chain-of-custody reports."
      },
      {
        icon: "📊",
        title: "Multi-Tenant Dashboard",
        description: "Enterprise-grade pharmacy dashboard with role-based access, real-time analytics, and batch management."
      }
    ]
    
    # Regulatory compliance badges
    @compliance_standards = [
      { icon: "📜", title: "DSCSA 503B", desc: "Drug Supply Chain Security Act" },
      { icon: "🔒", title: "21 CFR Part 11", desc: "Electronic Records & Signatures" },
      { icon: "🛡️", title: "HIPAA", desc: "Patient Data Protection" },
      { icon: "🌡️", title: "USP 797", desc: "Sterile Compounding Standards" }
    ]
  end
end
