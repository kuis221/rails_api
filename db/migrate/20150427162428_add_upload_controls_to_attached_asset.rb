class AddUploadControlsToAttachedAsset < ActiveRecord::Migration
  def change
    add_column :attached_assets, :status, :integer, default: 0
    add_column :attached_assets, :processing_percentage, :integer, default: 0
    AttachedAsset.where(processed: true).update_all(status: 2, processing_percentage: 100)
    AttachedAsset.where(processed: false).update_all(status: 0, processing_percentage: 0)
    remove_column :attached_assets, :processed, :boolean
  end
end
