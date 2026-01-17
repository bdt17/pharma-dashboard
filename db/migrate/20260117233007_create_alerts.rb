class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.text :message
      t.boolean :resolved

      t.timestamps
    end
  end
end
