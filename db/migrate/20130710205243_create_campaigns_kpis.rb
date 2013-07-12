class CreateCampaignsKpis < ActiveRecord::Migration
  def change
    create_table :campaigns_kpis do |t|
      t.references :campaign
      t.references :kpi
    end
    add_index :campaigns_kpis, :campaign_id
    add_index :campaigns_kpis, :kpi_id
  end
end
