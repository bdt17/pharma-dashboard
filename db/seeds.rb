# Production pharma data
Vehicle.create!([
  {imei: '123456789012345', name: 'Truck #1', status: 'active'},
  {imei: '123456789012346', name: 'Truck #2', status: 'active'}
]) unless Vehicle.count > 0

Batch.create!([
]) unless Batch.count > 0
25.times { |i| Vehicle.create!(imei: "GV55-\#{i+1.to_s.rjust(3,'0')}", latitude: 33.45+rand(-1..1)/10.0, longitude: -112.07+rand(-1..1)/10.0, name: "Truck \#{i+1}") }
