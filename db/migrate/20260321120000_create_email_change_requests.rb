class CreateEmailChangeRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :email_change_requests do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :new_email, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :email_change_requests, :token, unique: true
  end
end
