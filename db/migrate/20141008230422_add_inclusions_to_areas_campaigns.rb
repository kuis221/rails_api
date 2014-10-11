class AddInclusionsToAreasCampaigns < ActiveRecord::Migration
  def change
    add_column :areas_campaigns, :inclusions, :integer, array: true, default: []
  end
end
