class ConsolidateVehiclePositionAndDeviceFields < ActiveRecord::Migration[8.1]
  def change
    # vehicles had both lat/lng and latitude/longitude -- two pairs of the
    # same thing (see the Phase 1 audit). latitude/longitude is what the
    # rest of the app (chain-of-custody PDF, policies) already reads.
    remove_column :vehicles, :lat, :float
    remove_column :vehicles, :lng, :float

    # Device identity and auth for the GPS ingest endpoint -- previously
    # nonexistent, so Api::V1::GpsController#update referenced columns
    # (speed, heading, last_ping) and a lookup key (`plates`, misspelled)
    # that never existed on this table at all.
    add_column :vehicles, :imei, :string
    add_column :vehicles, :api_token, :string
    add_column :vehicles, :speed, :float
    add_column :vehicles, :heading, :integer
    add_column :vehicles, :last_ping_at, :datetime

    add_index :vehicles, :imei, unique: true
    add_index :vehicles, :api_token, unique: true
  end
end
