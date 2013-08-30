class AddDirectUploadFieldsToAssetsTable < ActiveRecord::Migration
  def change
    add_column :attached_assets, :direct_upload_url, :string
    add_column :attached_assets, :processed, :boolean, default: false, null: false
    AttachedAsset.update_all(processed: true)
  end
end
