class AddActiveToBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :batches, :active, :boolean, default: true, null: false
  end
end
