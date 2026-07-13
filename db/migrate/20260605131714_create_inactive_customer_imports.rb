class CreateInactiveCustomerImports < ActiveRecord::Migration[8.1]
  def change
    create_table :inactive_customer_imports, id: :uuid do |t|
      t.string :aasm_state
      t.integer :records_count
      t.datetime :completed_at

      t.timestamps
    end
  end
end
