class DeleteCampaignKpisTable < ActiveRecord::Migration
  def change
    drop_table :campaigns_kpis
  end
end
