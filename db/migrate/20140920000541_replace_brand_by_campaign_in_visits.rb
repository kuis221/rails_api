class ReplaceBrandByCampaignInVisits < ActiveRecord::Migration
  def change
    add_column :brand_ambassadors_visits,  :campaign_id, :integer
    add_index :brand_ambassadors_visits,  :campaign_id
    remove_column :brand_ambassadors_visits,  :brand_id
  end
end
