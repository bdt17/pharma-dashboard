namespace :gps do
  task seed: :environment do
    puts "Seeding 25 pharma vehicles (Phoenix AZ)..."
    Vehicle.destroy_all
    Batch.destroy_all
    
    25.times do |i|
      v = Vehicle.create!(license_plate: "PHARMA#{sprintf("%03d", i+1)}",
                         lat: 33.4484 + rand(-0.05..0.05),
                         lng: -112.0740 + rand(-0.05..0.05),
                         status: %w[en_route idle delivered][rand(3)])
      Batch.create!(name: "LOT-PHX-#{Time.now.strftime('%Y%m%d')}-#{i+1}",
                   vehicle: v, temp_status: "2-8°C", compliance_status: "FDA ✓")
    end
    puts "✅ 25 vehicles + 25 batches LIVE"
  end
end
