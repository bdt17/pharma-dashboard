class AddFreeSetupToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :free_setup_owed_at, :datetime
    add_column :organizations, :free_setup_completed_at, :datetime
  end
end
