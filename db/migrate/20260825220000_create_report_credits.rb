class CreateReportCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :report_credits do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :stripe_checkout_session_id, null: false
      t.datetime :consumed_at

      t.timestamps
    end

    add_index :report_credits, :stripe_checkout_session_id, unique: true
  end
end
