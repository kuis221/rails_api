class AddCompanyIdToTables < ActiveRecord::Migration
  def change
    add_column :users, :company_id, :integer
    add_column :teams, :company_id, :integer
    add_column :campaigns, :company_id, :integer
  end
end
