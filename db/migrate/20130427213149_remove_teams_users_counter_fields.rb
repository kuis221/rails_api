class RemoveTeamsUsersCounterFields < ActiveRecord::Migration
  def change
    remove_column :teams, :users_count
    remove_column :users, :teams_count
  end
end
