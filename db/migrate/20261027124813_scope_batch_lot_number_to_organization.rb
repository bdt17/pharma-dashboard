# Lot numbers were unique across every organization, so one pharmacy's
# "has already been taken" error revealed another's lot numbers, and two
# pharmacies receiving the same manufacturer lot collided.
class ScopeBatchLotNumberToOrganization < ActiveRecord::Migration[8.1]
  def change
    remove_index :batches, :lot_number, unique: true, name: "index_batches_on_lot_number"
    add_index :batches, [ :organization_id, :lot_number ], unique: true
  end
end
