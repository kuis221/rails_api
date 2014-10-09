class AddFolderableColumnsToDocumentFoldersTable < ActiveRecord::Migration
  def change
    change_table :document_folders do |t|
      t.references :folderable, polymorphic: true
    end
  end
end
