class CreateActivityTypeCampaigns < ActiveRecord::Migration
  def change
    create_table :activity_type_campaigns do |t|
      t.references :activity_type
      t.references :campaign

      t.timestamps
    end
    add_index :activity_type_campaigns, :activity_type_id
    add_index :activity_type_campaigns, :campaign_id
  end
end
