class AddOrganizationForeignKeyToVehicles < ActiveRecord::Migration[8.1]
  def change
    # organization_id already existed as a bare bigint column with no
    # referential integrity. Enforce it now that Organization is the real
    # tenant boundary (see Phase 2 auth/authorization work).
    add_foreign_key :vehicles, :organizations
  end
end
