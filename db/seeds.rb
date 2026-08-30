# Idempotent seed data: one demo organization, a demo admin (outside
# production, or when SEED_ADMIN_PASSWORD is set), and a realistic populated
# dataset so a fresh checkout -- and the /ops page and every dashboard --
# has something real to look at instead of zeroes.
#
# Safe to run repeatedly. `bin/rails demo:reset` rebuilds just the demo
# org's operational data (vehicles/batches/custody/telemetry) from scratch.
#
# No password is ever hardcoded. Set SEED_ADMIN_PASSWORD to create a real
# login in a deployed environment; otherwise a random one is generated for
# local dev and printed once.

organization = Organization.find_or_create_by!(name: "Demo Pharma Transport") do |org|
  org.plan = "enterprise"
  org.status = "active"
end

admin_password = ENV["SEED_ADMIN_PASSWORD"]

if admin_password.blank? && Rails.env.production?
  puts "Seeded organization ##{organization.id} (#{organization.name}). " \
       "Skipped the demo admin: no SEED_ADMIN_PASSWORD set and this is production."
else
  generated = admin_password.blank?
  admin_password ||= SecureRandom.base58(20)

  user = User.find_or_create_by!(email: "admin@example.com") do |u|
    u.name = "Demo Admin"
    u.password = admin_password
    u.role = "admin"
    u.organization = organization
  end

  puts "Seeded organization ##{organization.id} and admin@example.com."
  puts "  Generated password (shown once): #{admin_password}" if generated && user.previously_new_record?
end

DemoData.populate!(organization) if organization.vehicles.none?

puts "Demo org now has #{organization.vehicles.count} vehicles, " \
     "#{organization.batches.count} batches " \
     "(#{organization.batches.non_compliant.count} in excursion), " \
     "#{CustodyLog.joins(:batch).where(batches: { organization_id: organization.id }).count} custody events."
