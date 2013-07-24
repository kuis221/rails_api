class RefactorDocumentsToAssets < ActiveRecord::Migration
  def change
    Document.destroy_all

    remove_column :documents, :file_file_name
    remove_column :documents, :file_content_type
    remove_column :documents, :file_file_size
    remove_column :documents, :file_updated_at
    remove_column :documents, :documentable_id
    remove_column :documents, :documentable_type
    add_column :documents, :event_id, :integer
    add_index :documents, :event_id

    create_table :attached_assets do |t|
      t.attachment :file
      t.string :asset_type
      t.references :attachable, :polymorphic => true
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :attached_assets, [:attachable_type, :attachable_id]

  end
end
