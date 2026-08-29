class CreateCallRequests < ActiveRecord::Migration[8.1]
  # Inbound "have someone call me" leads from the public marketing pages
  # (the compliance-officer retainer, the DSCSA readiness check, general).
  # Not tied to a user or organization -- these come from people who don't
  # have an account yet.
  def change
    create_table :call_requests do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :pharmacy_name
      t.string :phone
      t.string :topic, null: false
      t.text :message
      t.text :context
      t.datetime :handled_at

      t.timestamps
    end

    add_index :call_requests, :created_at
  end
end
