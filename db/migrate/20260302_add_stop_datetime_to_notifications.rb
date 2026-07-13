class AddStopDatetimeToNotifications < ActiveRecord::Migration[6.0]
  def change
    add_column :notifications, :stop_datetime, :datetime, null: true
    add_index :notifications, :stop_datetime
  end
end