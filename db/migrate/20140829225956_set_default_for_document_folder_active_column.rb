class SetDefaultForDocumentFolderActiveColumn < ActiveRecord::Migration
  def change
    change_column :document_folders, :active, :boolean, default: true
  end
end
