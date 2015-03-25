class AddTableauUsernameToCompanyUsers < ActiveRecord::Migration
  def change
    add_column :company_users, :tableau_username, :string
  end
end
