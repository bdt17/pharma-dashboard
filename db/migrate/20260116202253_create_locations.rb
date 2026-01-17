class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
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
