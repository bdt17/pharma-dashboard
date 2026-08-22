# Minimal, idempotent seed data: one organization, and (outside production,
# or when explicitly requested) one admin user to log in with locally.
# Safe to run repeatedly -- it only creates records if they don't already
# exist, and never touches anything else.
#
# No password is ever hardcoded here. Set SEED_ADMIN_PASSWORD in the
# environment if you want this to create a real login in a deployed
# environment; otherwise a random one is generated for local dev and
# printed once below.

organization = Organization.find_or_create_by!(name: "Demo Pharma Transport") do |org|
  org.plan = "enterprise"
  org.status = "active"
end

admin_password = ENV["SEED_ADMIN_PASSWORD"]

if admin_password.blank? && Rails.env.production?
  puts "Seeded organization ##{organization.id} (#{organization.name}). " \
       "Skipped creating the demo admin user: no SEED_ADMIN_PASSWORD was set " \
       "in this environment, and this is production, so no random/guessable " \
       "password was generated. Set SEED_ADMIN_PASSWORD and re-run db:seed " \
       "if you want a real login created here."
else
  generated = admin_password.blank?
  admin_password ||= SecureRandom.base58(20)

  user = User.find_or_create_by!(email: "admin@example.com") do |u|
    u.name = "Demo Admin"
    u.password = admin_password
    u.role = "admin"
    u.organization = organization
  end

  puts "Seeded organization ##{organization.id} (#{organization.name}) and admin@example.com."
  puts "  Generated password (shown once, not stored anywhere): #{admin_password}" if generated && user.previously_new_record?
end

# A sample vehicle/batch/custody event so a fresh local checkout has
# something real to look at in the chain-of-custody PDF, instead of an
# empty "no history" report.
vehicle = Vehicle.find_or_create_by!(name: "Demo Truck 1", organization: organization) do |v|
  v.identifier = "PHX-001"
  v.status = "active"
  v.imei = "860000000000001"
end

if vehicle.telemetries.none?
  vehicle.telemetries.create!(lat: 33.4484, lng: -112.0740, speed: 42.0, temp: 5.0, battery: 98.0)
end

batch = Batch.find_or_create_by!(lot_number: "LOT-DEMO-001") do |b|
  b.name = "Demo Insulin Batch"
  b.organization = organization
  b.vehicle = vehicle
  b.temperature_celsius = 5.0
  b.status = "in_transit"
end

if batch.custody_logs.none?
  batch.custody_logs.create!(action_type: "pickup", handler_name: "Demo Handler", location: "Phoenix, AZ warehouse")
end

puts "Seeded vehicle ##{vehicle.id} (imei=#{vehicle.imei}). " \
     "To POST a GPS ping locally: curl -X POST http://localhost:3000/api/v1/gps " \
     "-H 'X-Device-Token: #{vehicle.api_token}' " \
     "-d 'imei=#{vehicle.imei}&lat=33.45&lng=-112.08'"
