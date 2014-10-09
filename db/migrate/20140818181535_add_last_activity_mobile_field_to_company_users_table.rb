class AddLastActivityMobileFieldToCompanyUsersTable < ActiveRecord::Migration
  def change
    add_column :company_users, :last_activity_mobile_at, :datetime
  end
end
