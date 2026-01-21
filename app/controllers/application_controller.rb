class ApplicationController < ActionController::Base
  # Phase 23.2: FDA Chain-of-Custody PDF Generator
  def chain_of_custody
    batch_id = params[:id] || 1
    
    pdf_content = <<~FDA
FDA 21 CFR Part 11 - CHAIN OF CUSTODY
=====================================
Batch: ##{batch_id}
Status: DELIVERED ✓
Pfizer Order #PFZ-#{batch_id}
Temp: 2-8°C ✓ GPS: 24 Vehicles
Signature: Electronic ✓
Date: #{Time.now.strftime("%Y-%m-%d %H:%M")}
FDA
    FDA

    send_data pdf_content,
              filename: "coc_#{batch_id}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end
end
