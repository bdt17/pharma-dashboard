class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.float :lat
      t.float :lng
      t.float :speed
      t.float :heading
      t.integer :batch_id

      t.timestamps
    end
  end
end
