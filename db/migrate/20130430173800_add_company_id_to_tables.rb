class AddCompanyIdToTables < ActiveRecord::Migration
  def change
    add_column :users, :company_id, :integer
    add_column :teams, :company_id, :integer
    add_column :campaigns, :company_id, :integer

    add_index :users, :company_id
    add_index :teams, :company_id
    add_index :campaigns, :company_id
  end
end
