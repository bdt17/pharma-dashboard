# Generate realistic pharma transport data
50.times do |i|
  Vehicle.create!(
    name: "Truck ##{i+1}",
    status: %w[active idle maintenance][rand(3)],
    lat: 33.4484 + rand(-0.5..0.5),
    lng: -112.0740 + rand(-0.5..0.5),
    driver_id: rand(1..20)
  )
end

100.times do |i|
  Batch.create!(
    batch_id: "LOT-PHARMA-#{Time.current.year}#{i+1.to_s.rjust(4,'0')}",
    status: %w[loaded intransit delivered delayed][rand(4)],
    temperature: rand(2.0..8.0).round(1),
    destination: %w[Phoenix Tucson Flagstaff][rand(3)],
    created_at: rand(1.week.ago..Time.current)
  )
end

5.times { Alert.create!(message: "Temp alert: 9.2°C on LOT-PHARMA-#{rand(1000..9999)}", resolved: [true,false].sample) }
