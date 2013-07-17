class AddStatusToCompanyUserTable < ActiveRecord::Migration
  def change
    add_column :company_users, :active, :boolean, default: true
    remove_column :users, :aasm_state
  end
end
