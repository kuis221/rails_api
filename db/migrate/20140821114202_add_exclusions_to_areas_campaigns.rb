class AddExclusionsToAreasCampaigns < ActiveRecord::Migration
  def change
    add_column :areas_campaigns, :exclusions, :integer, array: true, default: []
  end
end
