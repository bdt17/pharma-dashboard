# db/migrate/20260116202255_create_audit_logs.rb
# Full corrected file - copy/paste entire contents:

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      # t.references :user, null: false, foreign_key: true
      t.references :batch, foreign_key: true
      t.string :event, null: false
      t.json :data                    # ✅ SQLite + PostgreSQL compatible
      t.string :ip_address, limit: 45  # ✅ IPv6 ready (45 chars max)
      t.timestamps
    end

    add_index :audit_logs, :event
    add_index :audit_logs, :ip_address
  end
end
