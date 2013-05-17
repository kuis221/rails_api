class CreateBrandsCampaignsTable < ActiveRecord::Migration
  def change
    create_table :brands_campaigns do |t|
      t.references :brand
      t.references :campaign
    end
    add_index :brands_campaigns, :brand_id
    add_index :brands_campaigns, :campaign_id
  end
end
