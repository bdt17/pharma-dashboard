# Production pharma data
Vehicle.create!([
  {imei: '123456789012345', name: 'Truck #1', status: 'active'},
  {imei: '123456789012346', name: 'Truck #2', status: 'active'}
]) unless Vehicle.count > 0

Batch.create!([
  {batch_id: 'LOT-PHARMA-20260204-001', status: 'in_transit', vehicle_id: 1},
  {batch_id: 'LOT-PHARMA-20260204-002', status: 'delivered', vehicle_id: 2}
]) unless Batch.count > 0
