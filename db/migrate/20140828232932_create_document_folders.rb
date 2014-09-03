class CreateDocumentFolders < ActiveRecord::Migration
  def change
    create_table :document_folders do |t|
      t.string :name
      t.references :parent, index: true
      t.boolean :active
      t.integer :documents_count
      t.references :company, index: true

      t.timestamps
    end

    add_column :attached_assets, :folder_id, :integer

    add_index :attached_assets, :folder_id
  end
end
