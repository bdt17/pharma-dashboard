class AddNameAndRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    # Skip if columns already exist
    unless column_exists?(:users, :name)
      add_column :users, :name, :string
    end
    
    unless column_exists?(:users, :role)
      add_column :users, :role, :string
    end
  end
end
