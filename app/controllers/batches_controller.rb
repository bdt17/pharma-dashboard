class BatchesController < ApplicationController
  def index
    render html: "<h1>💉 Batches Dashboard</h1><p>LOT-PHARMA-20260217 LIVE</p>".html_safe, layout: true
  end
  
  def chain_of_custody
    # Render static CoC PDF content
    pdf_content = "<h1>📄 Chain of Custody - LOT-PHARMA-20260217</h1><p>FDA DSCSA Compliant</p>"
    send_data pdf_content, filename: "coc.pdf", type: "application/pdf", disposition: "inline"
  end
end
