class CreateLocationPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :location_points do |t|
      t.bigint :vehicle_id  # No FK constraint during migration
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
