class DashboardController < ApplicationController
  def index
    @batches = 127
    @vehicles = 24
    @revenue = '$12K'
    @fleet = [
      "PHX-001 → Scottsdale (ETA 8min)",
      "PHX-002 → Tempe (ETA 12min)",
      "PHX-003 → Mesa (ETA 15min)",
      "PHX-004 → Glendale (ETA 9min)"
    ]
    @routes = [
      "CVS → Patient Home (42%)",
      "Walgreens → Patient Home (28%)",
      "Patient Home → Pharmacy (18%)",
      "Pharmacy → Hospital (12%)"
    ]
  render layout: false
  end
end
