class CreateBotBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :bot_blocks do |t|
      t.string :form, null: false
      t.string :reason, null: false
      t.datetime :created_at, null: false
    end
    add_index :bot_blocks, :created_at
  end
end
