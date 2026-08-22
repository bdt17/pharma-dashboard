# Generates the chain-of-custody compliance PDF for a single Batch: its
# identity, cold-chain compliance status, the full custody handoff history
# (CustodyLog), and the system audit trail for the batch (AuditLog). This is
# the one real, data-backed replacement for the half-dozen hardcoded PDF/HTML
# stubs that used to exist across the app (see the Phase 1 audit).
class PdfChainOfCustodyGenerator
  def initialize(batch)
    @batch = batch
  end

  def generate
    pdf = Prawn::Document.new(page_size: "LETTER", margin: 50)

    header(pdf)
    batch_details(pdf)
    custody_history(pdf)
    audit_trail(pdf)
    footer(pdf)

    pdf.render
  end

  private

  attr_reader :batch

  def header(pdf)
    pdf.fill_color "003366"
    pdf.text "Chain of Custody Report", size: 24, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 4
    pdf.text "Generated #{Time.current.strftime('%Y-%m-%d %H:%M %Z')}", size: 9, color: "666666"
    pdf.move_down 16
  end

  def batch_details(pdf)
    compliant = batch.compliance_status == "compliant"

    pdf.text "Lot #{batch.lot_number}", size: 16, style: :bold
    pdf.move_down 6
    pdf.table(
      [
        [ "Status", batch.status.presence || "unknown" ],
        [ "Organization", batch.organization&.name || "unknown" ],
        [ "Vehicle", batch.vehicle&.name || batch.vehicle&.identifier || "unassigned" ],
        [ "Driver", batch.driver&.email || "unassigned" ],
        [ "Temperature", batch.temperature_celsius ? "#{batch.temperature_celsius}°C" : "not recorded" ],
        [ "Compliance", compliant ? "COMPLIANT (2-8°C)" : batch.compliance_status.upcase ],
        [ "Expiry", batch.expiry&.to_s || "not set" ]
      ],
      cell_style: { size: 10, padding: 6 },
      column_widths: [ 130, 360 ]
    ) do
      row(5).text_color = compliant ? "1a7f37" : "b91c1c"
      row(5).font_style = :bold
    end
    pdf.move_down 20
  end

  def custody_history(pdf)
    pdf.text "Custody History", size: 14, style: :bold
    pdf.move_down 6

    logs = batch.custody_logs.to_a
    if logs.empty?
      pdf.text "No custody events recorded.", size: 10, style: :italic, color: "666666"
    else
      rows = [ [ "Time", "Action", "Handler", "Location", "Notes" ] ]
      logs.each do |log|
        rows << [
          log.timestamp&.strftime("%Y-%m-%d %H:%M") || "-",
          log.action_type,
          log.handler_name,
          log.location,
          log.condition_notes.presence || "-"
        ]
      end
      pdf.table(rows, header: true, cell_style: { size: 9, padding: 5 }, width: pdf.bounds.width) do
        row(0).background_color = "003366"
        row(0).text_color = "FFFFFF"
        row(0).font_style = :bold
      end
    end
    pdf.move_down 20
  end

  def audit_trail(pdf)
    pdf.text "Audit Trail", size: 14, style: :bold
    pdf.move_down 6

    logs = batch.audit_logs.order(created_at: :desc).limit(20).to_a
    if logs.empty?
      pdf.text "No audit events recorded.", size: 10, style: :italic, color: "666666"
    else
      rows = [ [ "Time", "User", "Event" ] ]
      logs.each do |log|
        rows << [ log.created_at.strftime("%Y-%m-%d %H:%M"), log.user.email, log.event ]
      end
      pdf.table(rows, header: true, cell_style: { size: 9, padding: 5 }, width: pdf.bounds.width) do
        row(0).background_color = "e5e7eb"
        row(0).font_style = :bold
      end
    end
  end

  def footer(pdf)
    pdf.move_down 24
    pdf.stroke_horizontal_rule
    pdf.move_down 8
    pdf.text "This document is a computer-generated record of the data held for batch ##{batch.id} " \
              "at the time of generation. It is not, on its own, a certification of regulatory compliance.",
              size: 8, color: "666666"
  end
end
