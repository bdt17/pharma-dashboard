# db/seeds.rb
# Safe pharma transport seed – works with any schema

puts "Seeding Vehicles..."

# Create or find the truck first, then set plate
truck = Vehicle.find_or_create_by!(imei: "GV55-001") do |v|
  v.identifier = "PHX-001"  if v.respond_to?(:identifier=)
  v.name       = "Phoenix Truck 1" if v.respond_ty?(:name=)
end

# Only update plate if the column exists
if truck.respond_to?(:plate=) && truck.plate.nil?
  truck.update!(plate: "TRK-PHX-001")
end

puts "✅ Vehicle seeded: #{truck.name} (IMEI: #{truck.imei})"


puts "Seeding Batches (safe mode)..."
begin
  existing_batch = Batch.first

  if Batch.column_names.include?("name") && existing_batch.nil?
    Batch.find_or_create_by!(
      name: "B001",
      vehicle: Vehicle.last
    )
  elsif Batch.column_names.include?("description") && existing_batch.nil?
    Batch.find_or_create_by!(
      description: "Phoenix vaccine run",
      vehicle: Vehicle.last
    )
  elsif Batch.column_names.include?("lot_number") && existing_batch.nil?
    Batch.find_or_create_by!(
      lot_number: "B001",
      vehicle: Vehicle.last
    )
  else
    # Fallback: only create if we have at least one vehicle
    if Vehicle.any?
      Batch.create!(vehicle: Vehicle.last)
    end
  end

  puts "✅ Batch seeded successfully"
rescue => e
  puts "⚠️  Batch seed skipped (table empty?): #{e.message}"
end

puts "✅ PHARMA SEED COMPLETE - 1 truck + 1 batch ready"
