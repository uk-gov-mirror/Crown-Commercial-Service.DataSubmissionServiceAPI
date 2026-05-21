class AddActiveToEmailChangeRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :email_change_requests, :active, :boolean, default: true, null: false
    add_index :email_change_requests, :active
  end
end
