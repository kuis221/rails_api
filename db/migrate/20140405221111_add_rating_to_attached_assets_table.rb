class AddRatingToAttachedAssetsTable < ActiveRecord::Migration
  def change
    add_column :attached_assets, :rating, :integer, default: 0
  end
end