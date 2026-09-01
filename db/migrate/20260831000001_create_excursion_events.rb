class CreateExcursionEvents < ActiveRecord::Migration[8.1]
  # A temperature excursion is an *interval*, not a point: a shipment's
  # sensor reads out of the 2-8°C range, stays there across some number of
  # pings, and (hopefully) comes back. One row per such interval, opened by
  # the first offending Telemetry reading and closed by the first reading
  # back in range. ExcursionMonitor is the only writer.
  def change
    create_table :excursion_events do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.float :trigger_temp, null: false
      t.float :peak_temp, null: false
      t.integer :readings_count, null: false, default: 1
      t.datetime :alerted_at
      t.timestamps
    end

    # At most one open excursion per batch at a time -- the safety net for
    # two near-simultaneous out-of-range pings both trying to open one.
    add_index :excursion_events, :batch_id,
      unique: true, where: "ended_at IS NULL", name: "index_excursion_events_one_open_per_batch"
  end
end
