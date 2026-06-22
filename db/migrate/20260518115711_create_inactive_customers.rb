class CreateInactiveCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :inactive_customers, id: :uuid do |t|
      t.integer :inactive_urn, null: false
      t.string :inactive_customer_name
      t.date :date_made_inactive

      t.integer :replacement_urn
      t.string :replacement_customer_name
      t.string :replacement_post_code
      t.string :replacement_status

      t.timestamps
    end

    add_index :inactive_customers, :inactive_urn, unique: true
  end
end
