# Builds a realistic operational dataset for a demo organization -- enough
# vehicles, batches, custody chains, telemetry and audit history that the
# dashboards, the compliance screen and the chain-of-custody PDFs show
# something meaningful. Used by db/seeds.rb and `bin/rails demo:reset`.
#
# Not for production customer data -- it only ever touches the org it's
# handed, and `reset!` deletes that org's operational records first.
module DemoData
  # last_ping_minutes_ago is only the seed value; for the active vehicles it
  # gets overwritten by Telemetry's vehicle-snapshot callback (see
  # build_telemetry). It's what makes PHX-003 look stale and MSA-001 offline.
  VEHICLES = [
    { name: "PHX-001", identifier: "PHX-001", imei: "860000000000001", status: "active",
      latitude: 33.4484, longitude: -112.0740, speed: 44.0, last_ping_minutes_ago: 3 },
    { name: "PHX-002", identifier: "PHX-002", imei: "860000000000002", status: "active",
      latitude: 33.3062, longitude: -111.8413, speed: 0.0, last_ping_minutes_ago: 8 },
    { name: "TUC-001", identifier: "TUC-001", imei: "860000000000003", status: "active",
      latitude: 32.2226, longitude: -110.9747, speed: 61.0, last_ping_minutes_ago: 1 },
    { name: "PHX-003", identifier: "PHX-003", imei: "860000000000004", status: "idle",
      latitude: 33.4936, longitude: -112.0931, speed: 0.0, last_ping_minutes_ago: 240 },
    { name: "MSA-001", identifier: "MSA-001", imei: "860000000000005", status: "maintenance",
      latitude: nil, longitude: nil, speed: nil, last_ping_minutes_ago: nil }
  ].freeze

  HANDLERS = [ "J. Ruiz", "M. Lee", "D. Okafor", "S. Nguyen", "A. Patel", "K. Brooks" ].freeze
  LOCATIONS = [ "Phoenix DC", "Mesa hub", "Scottsdale DC", "Tucson, AZ", "Chandler clinic", "Tempe pharmacy" ].freeze

  # 1x1 transparent PNG -- stand-in for a captured proof-of-delivery signature.
  TINY_PNG = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==".freeze

  def self.reset!(organization)
    batch_ids = organization.batches.ids
    CustodyLog.where(batch_id: batch_ids).delete_all
    Telemetry.where(batch_id: batch_ids).delete_all
    AuditLog.where(batch_id: batch_ids).delete_all
    ComplianceReport.where(batch_id: batch_ids).delete_all if defined?(ComplianceReport)
    organization.batches.destroy_all
    Telemetry.where(vehicle_id: organization.vehicles.ids).delete_all
    organization.vehicles.destroy_all
    AuditLog.where(user_id: organization.users.ids).delete_all
    populate!(organization)
  end

  def self.populate!(organization)
    vehicles = VEHICLES.map do |attrs|
      minutes = attrs[:last_ping_minutes_ago]
      organization.vehicles.create!(
        name: attrs[:name], identifier: attrs[:identifier], imei: attrs[:imei], status: attrs[:status],
        latitude: attrs[:latitude], longitude: attrs[:longitude], speed: attrs[:speed],
        last_ping_at: minutes && minutes.minutes.ago
      )
    end

    active_vehicles = vehicles.select { |v| v.status == "active" }

    # 14 batches: most compliant, 2 in excursion, 2 with no reading yet.
    14.times do |i|
      temperature =
        case i
        when 0, 1 then [ 11.4, 9.6 ][i]        # excursions
        when 2, 3 then nil                     # no reading
        else (3.0 + (i % 5)).round(1)          # 3.0 - 7.0, all compliant
        end

      delivered = i >= 8
      batch = organization.batches.create!(
        lot_number: "LOT-#{4460 + i}-#{('A'..'Z').to_a[i % 26]}",
        name: [ "Insulin glargine", "Adalimumab", "Influenza vaccine", "Rituximab", "Epoetin alfa" ][i % 5],
        vehicle: active_vehicles[i % active_vehicles.size],
        temperature_celsius: temperature,
        status: delivered ? "delivered" : "active"
      )

      build_custody_chain(batch, delivered:, day_offset: i)
      build_telemetry(batch, excursion: temperature && temperature > 8)
    end

    organization
  end

  def self.build_custody_chain(batch, delivered:, day_offset:)
    base = (day_offset + 1).days.ago
    steps = [ %w[pickup 0], %w[in_transit 2], %w[handoff 5] ]
    steps << %w[delivered 8] if delivered

    steps.each_with_index do |(action, hours), idx|
      handler = HANDLERS[(day_offset + idx) % HANDLERS.size]
      batch.custody_logs.create!(
        action_type: action,
        handler_name: handler,
        location: LOCATIONS[(day_offset + idx) % LOCATIONS.size],
        timestamp: base + hours.to_i.hours,
        signature_data: action == "delivered" ? { "image" => TINY_PNG, "signer_name" => handler } : nil
      )
    end
  end

  # Six readings over the last half hour, oldest first -- the newest is a
  # few minutes old, so Telemetry's after_create_commit leaves the vehicle
  # snapshot (last_ping_at etc.) looking current.
  def self.build_telemetry(batch, excursion:)
    6.times do |n|
      temp = excursion && n >= 3 ? (8.5 + n * 0.4).round(1) : (4.0 + rand * 2).round(1)
      batch.telemetries.create!(
        vehicle: batch.vehicle,
        lat: 33.4 + rand * 0.3, lng: -112.0 - rand * 0.3,
        speed: rand(65).to_f, temp: temp, battery: (90 + rand(10)).to_f,
        recorded_at: (30 - n * 5).minutes.ago
      )
    end
  end
end
