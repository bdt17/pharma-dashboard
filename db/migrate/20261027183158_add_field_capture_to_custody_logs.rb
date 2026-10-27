class AddFieldCaptureToCustodyLogs < ActiveRecord::Migration[8.1]
  def change
    # Who was signed in when the event was recorded -- handler_name stays
    # the free-text name of whoever physically had the product.
    add_reference :custody_logs, :recorded_by, foreign_key: { to_table: :users }
    # Browser GPS at the moment of handoff (driver mode on a phone).
    add_column :custody_logs, :latitude, :decimal, precision: 9, scale: 6
    add_column :custody_logs, :longitude, :decimal, precision: 9, scale: 6
    add_column :custody_logs, :location_accuracy_m, :integer
    # A probe reading typed in at pickup/delivery -- the no-hardware
    # cold-chain record.
    add_column :custody_logs, :temperature_celsius, :decimal, precision: 4, scale: 1
  end
end
