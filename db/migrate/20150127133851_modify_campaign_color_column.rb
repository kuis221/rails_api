class ModifyCampaignColorColumn < ActiveRecord::Migration
  def change
    change_column :campaigns, :color, :string, limit: 30
  end
end
