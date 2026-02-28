class CreateDrivers < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:drivers)
      create_table :drivers do |t|
        t.string :name
        t.string :email
        t.string :phone
        t.timestamps
      end
    end
  end
end
