class CreateBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :batches do |t|
      t.string :lot
      t.date :expiry
      t.string :status
      t.float :temperature_celsius

      t.timestamps
    end
    add_index :batches, :lot, unique: true
  end
end
