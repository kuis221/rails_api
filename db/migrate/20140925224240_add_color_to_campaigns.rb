class AddColorToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :color, :string, limit: 10
  end
end
