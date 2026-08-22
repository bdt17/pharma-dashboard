# Minimal, idempotent local-dev seed data: one organization and one admin
# user so `bin/rails db:seed` gives you something to log in with. Safe to
# run repeatedly -- it only creates records if they don't already exist, and
# never touches anything else.

organization = Organization.find_or_create_by!(name: "Demo Pharma Transport") do |org|
  org.plan = "enterprise"
  org.status = "active"
end

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Demo Admin"
  user.password = "password123!"
  user.role = "admin"
  user.organization = organization
end

puts "Seeded organization ##{organization.id} (#{organization.name}) and admin@example.com / password123!"
