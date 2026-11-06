# A few clearly labelled sample shipments for an empty account, so a new
# pharmacy sees what the dashboard, custody history, excursions and the
# chain-of-custody PDF look like before it has a delivery of its own.
#
# Unlike DemoData (which builds and wipes a whole demo organization), this
# runs on real customer organizations, so it is deliberately narrow:
#
# - Everything it creates is flagged `sample` (Batch.samples / Vehicle.samples)
#   and can be removed with clear! without touching anything real.
# - Sample batches are read-only (BatchPolicy refuses custody, packets and
#   edits on them) and sample vehicles are never offered for a real batch,
#   so real records can't end up attached to sample ones.
# - Telemetry goes in with insert_all, skipping Telemetry's callbacks, so
#   no excursion alert email, text or webhook ever fires for a sample.
# - Nothing here generates a Compliance Packet or touches the plan quota.
module SampleData
  LOT_PREFIX = "SAMPLE-".freeze
  RECIPIENT = "Sample Recipient".freeze
  # A drawn-looking scribble, so the signature on a sample delivery and its
  # PDF looks like one instead of a blank box.
  SIGNATURE_PATH = Rails.root.join("app/assets/images/sample-signature.png")

  VEHICLES = [
    { name: "Sample delivery van", identifier: "SAMPLE-VAN" },
    { name: "Sample delivery car", identifier: "SAMPLE-CAR" }
  ].freeze

  # Offered only to an account with no real shipments yet: once a pharmacy
  # has its own data, samples would just be noise next to it.
  def self.available?(organization)
    !organization.batches.real.exists? && !organization.sample_data?
  end

  def self.load!(organization, user: nil)
    return false unless available?(organization)

    now = Time.current
    ActiveRecord::Base.transaction do
      van, car = VEHICLES.map { |attrs| organization.vehicles.create!(**attrs, status: "active", sample: true) }

      delivered = build_batch(organization, van, "0001", "Insulin glargine", 5.1, "delivered")
      chain(delivered, user, [
        [ "pickup", now - 26.hours, "Main Street Pharmacy", 4.6 ],
        [ "delivered", now - 25.hours, "Sunrise Assisted Living", 5.1 ]
      ])
      readings(delivered, van, from: now - 26.hours, temps: [ 4.6, 4.9, 5.0, 5.2, 5.1 ])

      excursion = build_batch(organization, car, "0002", "Adalimumab", 9.4, "delivered")
      chain(excursion, user, [
        [ "pickup", now - 6.hours, "Main Street Pharmacy", 5.0 ],
        [ "delivered", now - 4.hours, "Hillside Clinic", 9.4 ]
      ])
      readings(excursion, car, from: now - 6.hours, temps: [ 5.0, 6.8, 8.9, 9.6, 9.4 ])
      ExcursionEvent.create!(batch: excursion, vehicle: car, started_at: now - 5.hours, ended_at: now - 4.hours,
                             trigger_temp: 8.9, peak_temp: 9.6, readings_count: 3, alerted_at: now - 5.hours)

      in_transit = build_batch(organization, van, "0003", "Influenza vaccine", 4.8, "active")
      chain(in_transit, user, [ [ "pickup", now - 40.minutes, "Main Street Pharmacy", 4.4 ] ])
      readings(in_transit, van, from: now - 40.minutes, temps: [ 4.4, 4.6, 4.8 ], step: 10.minutes)

      build_batch(organization, car, "0004", "Epoetin alfa", nil, "active")

      snapshot(van, lat: 33.4484, lng: -112.0740, at: now - 1.minute)
      snapshot(car, lat: 33.3062, lng: -111.8413, at: now - 4.hours)
    end
    true
  end

  # Removes every sample record and nothing else. Telemetry, custody logs,
  # excursions, audit entries and any packet tied to a sample batch go
  # with it; sample vehicles carry only sample batches (see the class note).
  def self.clear!(organization)
    ActiveRecord::Base.transaction do
      batch_ids = organization.batches.samples.ids
      vehicle_ids = organization.vehicles.samples.ids
      ExcursionEvent.where(batch_id: batch_ids).delete_all
      CustodyLog.where(batch_id: batch_ids).delete_all
      Telemetry.where(batch_id: batch_ids).or(Telemetry.where(vehicle_id: vehicle_ids)).delete_all
      AuditLog.where(batch_id: batch_ids).delete_all
      ComplianceReport.where(batch_id: batch_ids).delete_all
      Batch.where(id: batch_ids).delete_all
      Vehicle.where(id: vehicle_ids).where.not(id: Batch.where(vehicle_id: vehicle_ids).select(:vehicle_id)).delete_all
    end
  end

  def self.build_batch(organization, vehicle, number, product, temperature, status)
    organization.batches.create!(lot_number: "#{LOT_PREFIX}#{number}", name: "#{product} (sample)", vehicle: vehicle,
                                 temperature_celsius: temperature, status: status, sample: true)
  end

  def self.chain(batch, user, steps)
    steps.each do |action, at, location, temperature|
      batch.custody_logs.create!(
        action_type: action, handler_name: "Sample Driver", location: location, timestamp: at,
        temperature_celsius: temperature, recorded_by: user,
        latitude: 33.45 + rand * 0.1, longitude: -112.07 + rand * 0.1, location_accuracy_m: 12,
        signature_data: action == "delivered" ? { "image" => signature_data_url, "signer_name" => RECIPIENT } : nil
      )
    end
  end

  def self.signature_data_url
    "data:image/png;base64,#{Base64.strict_encode64(File.binread(SIGNATURE_PATH))}"
  end

  def self.readings(batch, vehicle, from:, temps:, step: 15.minutes)
    rows = temps.each_with_index.map do |temp, n|
      at = from + step * n
      { batch_id: batch.id, vehicle_id: vehicle.id, lat: 33.4 + n * 0.01, lng: -112.0 - n * 0.01,
        speed: 35.0, temp: temp, battery: 95.0, recorded_at: at, created_at: at, updated_at: at }
    end
    Telemetry.insert_all(rows)
  end

  def self.snapshot(vehicle, lat:, lng:, at:)
    vehicle.update_columns(latitude: lat, longitude: lng, speed: 0.0, last_ping_at: at)
  end

  private_class_method :build_batch, :chain, :signature_data_url, :readings, :snapshot
end
