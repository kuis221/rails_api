class CreateCampaingsUsersTable < ActiveRecord::Migration
  def change
    create_table :campaigns_users do |t|
      t.references :campaign
      t.references :user
    end
    add_index :campaigns_users, :campaign_id
    add_index :campaigns_users, :user_id
  end
end
