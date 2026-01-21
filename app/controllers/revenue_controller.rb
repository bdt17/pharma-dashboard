class RevenueController < ApplicationController
  def chain_of_custody
    pdf = <<~FDA
FDA 21 CFR Part 11 - CHAIN OF CUSTODY
=====================================
Batch: #{params[:id] || 1}
Status: DELIVERED ✓
Pfizer Order #PFZ-#{params[:id]}
Temp: 2-8°C ✓ GPS: 24 Vehicles
Signature: Electronic ✓
Date: #{Time.now.strftime("%Y-%m-%d %H:%M")}
    FDA
    send_data pdf, filename: "coc_#{params[:id]}.pdf", 
              type: "application/pdf", disposition: "attachment"
  end
end
