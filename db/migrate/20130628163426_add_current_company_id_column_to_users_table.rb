class AddCurrentCompanyIdColumnToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :current_company_id, :integer
    User.all.each { |u| u.update_column(:current_company_id, u.companies.first.id) if u.company_ids.size > 0 }
  end
end
