class DropRedundantLocationTables < ActiveRecord::Migration[8.1]
  def change
    # Four separate tables independently reinvented "where is the vehicle
    # right now" (see the Phase 1 audit): gps_events, gps_locations,
    # location_points, locations. None had a model; nothing ever wrote to
    # or read from any of them. `telemetries` -- richer (links to both
    # Vehicle and Batch, carries temperature/battery/signal) and now backed
    # by a real Telemetry model -- is the one canonical table going forward.
    drop_table :gps_events, force: :cascade do |t|
      t.string :imei
      t.float :latitude
      t.float :longitude
      t.float :temperature
      t.integer :vehicle_id
      t.timestamps
    end

    drop_table :gps_locations, force: :cascade do |t|
      t.string :device_imei
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.boolean :ignition_status
      t.datetime :received_at
      t.timestamps
    end

    drop_table :location_points, force: :cascade do |t|
      t.bigint :vehicle_id
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.datetime :recorded_at
      t.timestamps
    end

    drop_table :locations, force: :cascade do |t|
      t.integer :vehicle_id
      t.float :lat
      t.float :lng
      t.float :speed
      t.float :heading
      t.datetime :timestamp
      t.timestamps
    end
  end
end
