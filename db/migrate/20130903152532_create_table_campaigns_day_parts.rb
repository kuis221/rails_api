class CreateTableCampaignsDayParts < ActiveRecord::Migration
  def change
    create_table :campaigns_day_parts do |t|
      t.references :campaign
      t.references :day_part
    end
  end
end
