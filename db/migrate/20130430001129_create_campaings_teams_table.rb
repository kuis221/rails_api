class CreateCampaingsTeamsTable < ActiveRecord::Migration
  def change
    create_table :campaigns_teams do |t|
      t.references :campaign
      t.references :team
    end
    add_index :campaigns_teams, :campaign_id
    add_index :campaigns_teams, :team_id
  end
end
