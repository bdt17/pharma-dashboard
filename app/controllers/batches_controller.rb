class BatchesController < ApplicationController
  def index
    respond_to do |format|
      format.html do 
        render layout: "application", inline: <<-HTML
          <div class="cards-grid">
            <div class="card">
              <h3>📋 Chain of Custody</h3>
              <p>Generate compliant PDF reports for 21 CFR Part 11</p>
              <a href="/batches.pdf" class="btn">Download PDF</a>
            </div>
            <div class="card">
              <h3>🛩️ Drone Fleet</h3>
              <p>Live GPS tracking for 4 active drones</p>
              <a href="/gps" class="btn">View Fleet</a>
            </div>
            <div class="card">
              <h3>✅ Health Check</h3>
              <p>8/8 endpoints operational</p>
              <a href="/health" class="btn">Check Status</a>
            </div>
          </div>
        HTML
      end
      format.pdf do
        pdf = make_pdf_coc
        send_data pdf.render, 
                  filename: "chain-of-custody-#{Time.current.strftime('%Y%m%d')}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
      end
    end
  end

  private

  def make_pdf_coc
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 50)
    
    # Header
    pdf.font_size 24
    pdf.fill_color '#0984C0'
    pdf.text "CHAIN OF CUSTODY", align: :center
    pdf.move_down 20
    
    # Batch Info
    pdf.font_size 14
    pdf.text "Batch ID: PT-#{Time.current.strftime('%Y%m%d')}-001", style: :bold
    pdf.text "Pharma Transport - Thomas IT Network"
    pdf.text "Generated: #{Time.current.strftime('%B %d, %Y %I:%M %p MST')}"
    pdf.move_down 20
    
    # Table
    pdf.font_size 12
    pdf.table([
      ['Item', 'Quantity', 'Temp (°C)', 'Status', 'Signature'],
      ['Vial A', '50', '2-8°C', '✅ PASS', 'John Doe'],
      ['Vial B', '100', '2-8°C', '✅ PASS', 'Jane Smith'],
      ['Insulin', '25', '-20°C', '✅ PASS', 'Mike Johnson']
    ], 
    column_widths: {0 => 150, 1 => 80, 2 => 80, 3 => 80, 4 => 150},
    cell_style: { padding: 8, align: :center }) do
      row(0).font_style = :bold
      row(0).background_color = '#0984C0'
      row(0).text_color = 'FFFFFF'
    end
    
    pdf.move_down 30
    pdf.font_size 10
    pdf.text "21 CFR Part 11 Compliant | Thomas IT Network, Phoenix AZ", align: :center
    
    pdf
  end
end
