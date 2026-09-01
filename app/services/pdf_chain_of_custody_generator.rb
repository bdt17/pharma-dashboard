# Generates the chain-of-custody compliance PDF for a single Batch: its
# identity, cold-chain compliance status, the full custody handoff history
# (CustodyLog), captured signatures, and the system audit trail for the
# batch (AuditLog). This is the one real, data-backed replacement for the
# half-dozen hardcoded PDF/HTML stubs that used to exist across the app
# (see the Phase 1 audit).
require "base64"
require "stringio"

class PdfChainOfCustodyGenerator
  def initialize(batch)
    @batch = batch
  end

  def generate
    pdf = Prawn::Document.new(page_size: "LETTER", margin: 50)

    header(pdf)
    batch_details(pdf)
    temperature_monitoring(pdf)
    custody_history(pdf)
    signatures(pdf)
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

  # Real time-series sensor data (Telemetry), not just the single snapshot
  # in the details table above -- this is what "temperature-monitoring
  # reference" and "temperature excursion" actually mean for a shipment
  # in transit, not a single point-in-time reading.
  def temperature_monitoring(pdf)
    pdf.text "Temperature Monitoring", size: 14, style: :bold
    pdf.move_down 6

    readings = batch.telemetries.where.not(temp: nil).to_a
    excursions = batch.temperature_excursions.to_a
    events = batch.excursion_events.recent_first.to_a

    if readings.empty? && events.empty?
      pdf.text "No temperature-monitoring data recorded for this shipment.", size: 10, style: :italic, color: "666666"
    else
      pdf.text "#{monitoring_summary(readings, excursions, events)}.", size: 10
      pdf.move_down 6

      excursion_events_table(pdf, events) if events.any?
      excursion_readings_table(pdf, excursions) if excursions.any?
    end
    pdf.move_down 20
  end

  def monitoring_summary(readings, excursions, events)
    parts = []
    if readings.any?
      temps = readings.map(&:temp)
      parts << "#{readings.size} reading#{'s' unless readings.size == 1} " \
               "(#{temps.min}°C to #{temps.max}°C) -- #{excursions.size} outside the 2-8°C range"
    end
    if events.any?
      lead = readings.any? ? "across " : "#{excursions.size} readings outside the 2-8°C range, across "
      parts << "#{lead}#{events.size} excursion event#{'s' unless events.size == 1}"
    end
    parts.join(" ")
  end

  # One row per excursion *interval* (ExcursionEvent) -- the summary an
  # auditor reads first: when the shipment went out of range, for how
  # long, which way, and how far.
  def excursion_events_table(pdf, events)
    rows = [ [ "Started", "Ended", "Duration", "Direction", "Peak", "Readings" ] ]
    events.each do |event|
      rows << [
        event.started_at.strftime("%Y-%m-%d %H:%M"),
        event.ended_at ? event.ended_at.strftime("%Y-%m-%d %H:%M") : "ongoing",
        humanized_duration(event.duration),
        event.direction,
        "#{event.peak_temp}°C",
        event.readings_count.to_s
      ]
    end
    pdf.table(rows, header: true, cell_style: { size: 9, padding: 5 }, width: pdf.bounds.width) do
      row(0).background_color = "b91c1c"
      row(0).text_color = "FFFFFF"
      row(0).font_style = :bold
    end
    pdf.move_down 8
  end

  # Every individual out-of-range reading -- the forensic detail behind
  # the event summary above. Kept separately because historical telemetry
  # from before excursion events were tracked still shows up here.
  def excursion_readings_table(pdf, excursions)
    rows = [ [ "Time", "Temperature", "Location" ] ]
    excursions.each do |reading|
      rows << [
        reading.recorded_at&.strftime("%Y-%m-%d %H:%M") || "-",
        "#{reading.temp}°C",
        reading.lat && reading.lng ? "#{reading.lat.round(4)}, #{reading.lng.round(4)}" : "-"
      ]
    end
    pdf.table(rows, header: true, cell_style: { size: 9, padding: 5 }, width: pdf.bounds.width) do
      row(0).background_color = "b91c1c"
      row(0).text_color = "FFFFFF"
      row(0).font_style = :bold
    end
  end

  # Compact "1h 15m" / "42m" / "30s" -- distance_of_time_in_words isn't
  # available outside a view, and its "about 1 hour" phrasing is too loose
  # for a compliance record anyway.
  def humanized_duration(seconds)
    seconds = seconds.round
    return "#{seconds}s" if seconds < 60

    minutes, = seconds.divmod(60)
    hours, minutes = minutes.divmod(60)
    hours.positive? ? "#{hours}h #{minutes}m" : "#{minutes}m"
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

  # Renders each captured signature as an actual embedded image, not just
  # a note that one exists. A signature is proof tied to a specific custody
  # event (most importantly "delivered"), so this lives as its own section
  # rather than trying to cram an image into a custody_history table cell.
  def signatures(pdf)
    signed_logs = batch.custody_logs.select(&:signed?)
    return if signed_logs.empty?

    pdf.text "Signatures", size: 14, style: :bold
    pdf.move_down 6

    signed_logs.each do |log|
      data = log.signature_data
      pdf.text "#{log.action_type.humanize} -- #{data['signer_name']} (#{data['signer_role'].presence || 'signer'})",
                size: 10, style: :bold
      # The explicit move_down here matters, not just cosmetic spacing: two
      # pdf.text calls back-to-back at different font sizes can end up
      # overlapping in Prawn depending on the exact cursor position (hit
      # this for real -- the signer name line silently vanished under the
      # line below it at certain page positions). A move_down between them
      # forces a clean baseline instead of relying on Prawn's implicit
      # line-height advance.
      pdf.move_down 2
      pdf.text [ data["signed_at"], data["ip_address"] ].compact.join(" from "), size: 8, color: "666666"
      pdf.move_down 4

      image_bytes = decode_signature_image(data["image"])
      pdf.image StringIO.new(image_bytes), width: 150 if image_bytes
      pdf.move_down 14
    end
  end

  def decode_signature_image(data_url)
    return nil if data_url.blank?

    Base64.decode64(data_url.sub(/\Adata:image\/\w+;base64,/, ""))
  rescue StandardError
    nil
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
