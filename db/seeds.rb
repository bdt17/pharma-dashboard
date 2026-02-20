# Phase 8 Test Data - Chain of Custody PDFs
puts "🌡️ Seeding Pharma Dashboard test data..."

User.find_or_create_by!(email: 'admin@pharmagps.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
end
puts "✅ Admin: admin@pharmagps.com / password123"

batch = Batch.find_or_create_by!(lot_number: 'LOT-PHARMA-20260219') do |b|
  b.user = User.first
end
puts "✅ Batch: #{batch.lot_number} (ID: #{batch.id})"

# Locations
locations = [
  { name: 'Phoenix Depot', lat: 33.4484, lng: -112.0740 },
  { name: 'Mesa Distribution', lat: 33.4152, lng: -111.8315 },
  { name: 'Tempe Hospital', lat: 33.4255, lng: -111.9400 }
].map { |loc| Location.find_or_create_by!(loc) }

# Drivers
drivers = [
  { name: 'John Driver', phone: '+14805551234' },
  { name: 'Sarah Haul', phone: '+14805556789' },
  { name: 'Mike Transport', phone: '+14805552345' }
].map { |drv| Driver.find_or_create_by!(drv) }

# Compliance logs
3.times do |i|
  ComplianceLog.create!(
    batch: batch,
    location: locations[i],
    driver: drivers[i],
    temperature: [4.2, 6.8, 3.1][i],
    fda_compliant: true,
    notes: "2-8°C maintained ✓"
  )
end
puts "✅ 3 compliance logs"
puts "🎉 Test: /batches/#{batch.id}/custody_report.pdf"
