class CreateTableCampaignsDateRanges < ActiveRecord::Migration
  def change
    create_table :campaigns_date_ranges do |t|
      t.references :campaign
      t.references :date_range
    end
  end
end
