class CreateLocationPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :location_points do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
