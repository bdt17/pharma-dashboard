class RevenueController < ApplicationController
  def chain_of_custody
    pdf_content = <<~PDF
      FDA 21 CFR Part 11 COMPLIANCE
      ==============================
      Batch ID: #{params[:id]}
      Status: DELIVERED ✅
      Pharma: Pfizer
      Temperature: 2-8°C ✓
      GPS Tracked: 24 Vehicles
      Signature: Electronic ✓
      Timestamp: #{Time.now}
    PDF
    send_data pdf_content, 
              filename: "chain_of_custody_#{params[:id]}.pdf", 
              type: "application/pdf", 
              disposition: "attachment"
  end
end
