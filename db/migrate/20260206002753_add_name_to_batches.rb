class AddNameToBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :batches, :name, :string unless column_exists?(:batches, :name)
  end
end
