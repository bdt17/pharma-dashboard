class CreateComplianceReports < ActiveRecord::Migration[8.1]
  def change
    # One immutable row per generated Compliance Packet -- the tamper-
    # evident version ledger. Never updated after creation; a correction
    # is a new version, not an edit (same rationale as CustodyLog).
    create_table :compliance_reports do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :generated_by, null: false, foreign_key: { to_table: :users }

      # Per-batch sequence: 1, 2, 3... enforced unique below so two
      # concurrent generations can never claim the same version number.
      t.integer :version, null: false

      # SHA-256 hex digest of the exact rendered PDF bytes at generation
      # time -- lets anyone holding both the file and this record verify
      # independently that the file hasn't changed since it was issued.
      t.string :content_hash, null: false

      # Links to the prior version's content_hash (null for version 1),
      # forming a simple hash chain: altering or deleting a past version
      # becomes detectable because it breaks every version after it.
      t.string :previous_hash

      t.timestamps
    end

    add_index :compliance_reports, [ :batch_id, :version ], unique: true
  end
end
