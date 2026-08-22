class AddDriverAndOrganizationForeignKeyToBatches < ActiveRecord::Migration[8.1]
  def change
    # Batch already declared `belongs_to :driver, class_name: 'User'` in the
    # model, but no `driver_id` column ever existed — the association was
    # dead on arrival. Add it for real, referencing the consolidated `users`
    # table (drivers are now a User role, not a separate model/table).
    add_reference :batches, :driver, foreign_key: { to_table: :users }

    add_foreign_key :batches, :organizations

    # Same redundant free-text tenant_id as `users` — `organization_id`
    # (now FK-enforced) is the one real tenant boundary going forward.
    remove_column :batches, :tenant_id, :uuid
  end
end
