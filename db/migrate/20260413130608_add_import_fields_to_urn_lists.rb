class AddImportFieldsToUrnLists < ActiveRecord::Migration[8.1]
  def change
    add_column :urn_lists, :source, :string, null: false, default: 'manual_upload'
    add_column :urn_lists, :completed_at, :datetime
    add_column :urn_lists, :processed_count, :integer

    add_index :urn_lists, :source
    add_index :urn_lists, :completed_at
  end
end
