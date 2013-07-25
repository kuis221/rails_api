class AddActiveFieldToAttachedAssetsTable < ActiveRecord::Migration
  def change
    add_column :attached_assets, :active, :boolean, default: true
  end
end
