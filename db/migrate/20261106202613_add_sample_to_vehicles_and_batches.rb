class AddSampleToVehiclesAndBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :sample, :boolean, default: false, null: false
    add_column :batches, :sample, :boolean, default: false, null: false
  end
end
