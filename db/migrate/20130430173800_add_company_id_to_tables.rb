class AddCompanyIdToTables < ActiveRecord::Migration
  def change
    add_column :users, :company_id, :integer
    add_column :teams, :company_id, :integer
    add_column :campaigns, :company_id, :integer

    c = Company.create(name: 'Test Company')
    User.update_all(:company_id => c.id)
    Team.update_all(:company_id => c.id)
    Campaign.update_all(:company_id => c.id)
  end
end
