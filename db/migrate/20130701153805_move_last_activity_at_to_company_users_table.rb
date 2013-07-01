class MoveLastActivityAtToCompanyUsersTable < ActiveRecord::Migration
  def change
    add_column :company_users, :last_activity_at, :datetime
    remove_column :users, :last_activity_at
  end
end
