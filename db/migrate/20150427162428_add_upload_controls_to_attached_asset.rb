class AddUploadControlsToAttachedAsset < ActiveRecord::Migration
  def change
    add_column :attached_assets, :aasm_state, :string
    add_column :attached_assets, :upload_percentage, :integer
    AttachedAsset.all.each { |a| a.processed == true ? a.update_attributes(aasm_state: 'completed', upload_percentage: 100) : a.update_attributes(aasm_state: 'failed', upload_percentage: 0) }
  end
end
