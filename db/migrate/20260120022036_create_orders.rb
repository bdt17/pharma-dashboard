class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :pharmacy, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.string :status
      t.string :tracking_id

      t.timestamps
    end
  end
end
