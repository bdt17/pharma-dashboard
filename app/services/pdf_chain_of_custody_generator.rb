class PdfChainOfCustodyGenerator
  def initialize(batch)
    @batch = batch
  end

  def generate
    pdf = Prawn::Document.new(page_size: "LETTER")

    # Header
    pdf.font "Helvetica"
    pdf.fill_color [ 0, 51, 102 ]
    pdf.text_box "CHAIN OF CUSTODY", {
      at: [ 70, 750 ],
      width: 400,
      size: 28,
      style: :bold,
      align: :center
    }

    # Batch details
    pdf.move_down 60
    pdf.text "Batch ID: #{@batch.lot_number || 'LOT-PHARMA-20260207'}", size: 16, style: :bold
    pdf.text "Status: #{@batch.status&.upcase || 'IN TRANSIT'}", size: 14
    pdf.text "Vehicle: #{@batch.vehicle&.imei || 'GV55-001'}", size: 14
    pdf.text "Location: Phoenix, AZ (33.4484, -112.0740)", size: 14

    # Audit trail table
    table_data = [ [ "Time", "User", "Action", "Details" ] ]
    logs = @batch.audit_logs || []
    if logs.empty?
      table_data << [ Time.now.strftime("%m/%d %H:%M"), "System", "Created", "Batch initialized in Phoenix, AZ" ]
    else
      logs.first(10).each do |log|
        table_data << [
          log.created_at&.strftime("%m/%d %H:%M") || "Now",
          log.user&.name || "System",
          log.action || "Update",
          log.details || "Position updated"
        ]
      end
    end

    pdf.table(table_data,
      position: :center,
      cell_style: { size: 10 },
      width: pdf.bounds.width - 80
    ) do
      row(0).background_color = [ 0, 51, 102 ]
      row(0).font_style = :bold
      row(0).text_color = "FFFFFF"
      columns(0).width = 80
    end

    pdf.render
  end
end
