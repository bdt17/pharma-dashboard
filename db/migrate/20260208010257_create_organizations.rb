class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :subdomain
      t.string :stripe_customer_id
      t.string :plan
      t.string :status

      t.timestamps
    end
    add_index :organizations, :subdomain, unique: true
  end
end
