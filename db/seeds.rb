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
