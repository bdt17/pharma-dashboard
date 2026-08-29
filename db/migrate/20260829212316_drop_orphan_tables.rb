class DropOrphanTables < ActiveRecord::Migration[8.1]
  # alerts, revenues, orders, and patients are leftover scaffolding: no
  # model, no controller, no reference anywhere in app/, lib/, or config/.
  # `patients` is an abandoned second Devise table; `orders` is the only one
  # with a foreign key (orders -> patients), so it's dropped first.
  #
  # Reversible: the down migration recreates the structure (not any data --
  # these tables have never been written to by application code).
  def change
    drop_table :orders do |t|
      t.bigint :patient_id, null: false
      t.bigint :pharmacy_id
      t.string :status
      t.string :tracking_id
      t.timestamps
      t.index :patient_id
    end

    drop_table :patients do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
      t.index :email, unique: true
      t.index :reset_password_token, unique: true
    end

    drop_table :alerts do |t|
      t.text :message
      t.boolean :resolved
      t.timestamps
    end

    drop_table :revenues do |t|
      t.decimal :amount
      t.date :date
      t.timestamps
    end
  end
end
