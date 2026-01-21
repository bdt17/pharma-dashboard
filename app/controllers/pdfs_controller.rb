class PdfsController < ApplicationController
  def chain_of_custody
    pdf_content = "FDA 21 CFR Part 11 - CHAIN OF CUSTODY\n" +
                  "=====================================\n" +
                  "Batch: #{params[:id] || 1}\n" +
                  "Status: DELIVERED ✓\n" +
                  "Pfizer Order #PFZ-#{params[:id]}\n" +
                  "Temp: 2-8°C ✓ GPS: 24 Vehicles\n" +
                  "Signature: Electronic ✓\n" +
                  "Date: #{Time.now.strftime("%Y-%m-%d %H:%M")}\n"

    send_data pdf_content, 
              filename: "coc_#{params[:id]}.pdf",
              type: "application/pdf", 
              disposition: "attachment"
  end
end
