# Found by actually looking at the new self-serve "Add a batch" form in a
# real browser: Batch.new pre-filled lot_number with this DB default, so
# the text field rendered "LOT-UNASSIGNED" as a real value, not a
# placeholder. lot_number is also uniquely indexed, so only the first
# customer to leave the field untouched would even succeed -- every
# batch after that would fail with a confusing "has already been taken"
# error for a value they never typed. Nothing in the app ever relied on
# the default (every real call site already supplies its own lot_number);
# it also made Batch's `validates :lot_number, presence: true` dead code,
# since the column could never actually arrive blank. NOT NULL is
# unchanged -- the model validation is what enforces presence now.
class RemoveDefaultFromBatchesLotNumber < ActiveRecord::Migration[8.1]
  def up
    change_column_default :batches, :lot_number, from: "LOT-UNASSIGNED", to: nil
  end

  def down
    change_column_default :batches, :lot_number, from: nil, to: "LOT-UNASSIGNED"
  end
end
