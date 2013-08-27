class CreateAssetDownloads < ActiveRecord::Migration
  def change
    create_table :asset_downloads do |t|
      t.string :uid
      t.text :assets_ids
      t.string :aasm_state
      t.attachment :file
      t.references :user
      t.datetime :last_downloaded

      t.timestamps
    end
    add_index :asset_downloads, :user_id
  end
end
