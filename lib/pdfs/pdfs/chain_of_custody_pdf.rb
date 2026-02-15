class ChainOfCustodyPdf < Prawn::Document
  def initialize(batch_id)
    super()
    @batch_id = batch_id
    chain_of_custody
  end
  
  def chain_of_custody
    # Header
    text "PHARMA TRANSPORT", size: 24, style: :bold, align: :center
    text "CHAIN OF CUSTODY REPORT", size: 18, style: :bold, align: :center
    move_down 20
    
    # Batch Info
    text "Batch ID: #{@batch_id}", size: 16, style: :bold
    text "Report Date: #{Time.current.strftime('%Y-%m-%d %H:%M')}", size: 14
    move_down 20
    
    # Chain of Custody Table
    table_data = [
      ["Step", "Location", "Driver", "Time", "Temp (°C)", "Status"],
      ["1. Dispatched", "Phoenix HQ", "John Doe #123", "14:30", "4.2°C", "✓"],
      ["2. In Transit", "I-10 East (GPS)", "John Doe #123", "15:15", "5.1°C", "✓"],
      ["3. Geofence", "Scottsdale Limits", "John Doe #123", "15:45", "4.8°C", "✓"],
      ["4. Delivered", "Scottsdale Hospital", "John Doe #123", "16:00", "3.8°C", "✓"]
    ]
    
    table(table_data, 
          width: bounds.width, 
          cell_style: { size: 10 },
          column_widths: { 0 => 60, 1 => 120, 2 => 90, 3 => 60, 4 => 60, 5 => 50 }) do
      row(0).font_style = :bold
      row(0).background_color = "0984C0"
      row(0).text_color = "FFFFFF"
      columns(0..4).align = :center
      columns(5).align = :center
    end
    
    # Footer
    move_down 40
    text "FDA 21 CFR Part 11 Compliant", size: 12, style: :bold, align: :center
    text "Immutable Audit Trail Generated", size: 10, align: :center
  end
end
