class DropOrphanedAuditsTable < ActiveRecord::Migration[8.1]
  def change
    # Leftover from an `audited` gem install that never made it into the
    # Gemfile (see the Phase 1 audit) -- no model, nothing ever wrote to it.
    # `audit_logs` (with a real AuditLog model as of this migration) is the
    # one real audit trail table going forward.
    drop_table :audits, force: :cascade do |t|
      t.string :auditable_type
      t.integer :auditable_id
      t.string :associated_type
      t.integer :associated_id
      t.integer :user_id
      t.string :user_type
      t.string :username
      t.string :action
      t.text :audited_changes
      t.integer :version, default: 0
      t.string :comment
      t.string :remote_address
      t.string :request_uuid
      t.datetime :created_at
      t.index [ :auditable_type, :auditable_id, :version ], name: "auditable_index"
      t.index [ :associated_type, :associated_id ], name: "associated_index"
      t.index [ :user_id, :user_type ], name: "user_index"
      t.index :request_uuid
      t.index :created_at
    end
  end
end
