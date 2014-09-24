class AddDirectUploadUrlIndexToAttachedAssets < ActiveRecord::Migration
  def change
    add_index :attached_assets, :direct_upload_url, unique: true
  end
end
