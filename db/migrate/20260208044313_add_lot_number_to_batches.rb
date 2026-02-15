class AddLotNumberToBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :batches, :lot_number, :string, null: false, default: 'LOT-UNASSIGNED'
    add_index :batches, :lot_number, unique: true
  end
end
