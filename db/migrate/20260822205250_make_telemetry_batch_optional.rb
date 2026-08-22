class MakeTelemetryBatchOptional < ActiveRecord::Migration[8.1]
  def change
    # A GPS/telemetry ping happens whenever a device is on, whether or not
    # the vehicle currently has an active batch assigned (idle, empty return
    # trip, etc.) -- requiring batch_id made it impossible to ever record
    # those pings.
    change_column_null :telemetries, :batch_id, true
  end
end
