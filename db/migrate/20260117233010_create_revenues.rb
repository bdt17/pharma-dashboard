class CreateRevenues < ActiveRecord::Migration[8.1]
  def change
    create_table :revenues do |t|
      t.date :date
      t.decimal :amount

      t.timestamps
    end
  end
end
