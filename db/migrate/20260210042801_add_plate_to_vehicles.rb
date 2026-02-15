class AddPlateToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :plate, :string
  end
end
