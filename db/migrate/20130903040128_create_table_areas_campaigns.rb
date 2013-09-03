class CreateTableAreasCampaigns < ActiveRecord::Migration
  def change
    create_table :areas_campaigns do |t|
      t.references :area
      t.references :campaign
    end
  end
end
