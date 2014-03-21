class CreateAttachedAssetsTagsTable < ActiveRecord::Migration
  def change
    create_table :attached_assets_tags do |t|
      t.references :attached_asset
      t.references :tag
    end
    add_index :attached_assets_tags, :attached_asset_id
    add_index :attached_assets_tags, :tag_id
  end
end
