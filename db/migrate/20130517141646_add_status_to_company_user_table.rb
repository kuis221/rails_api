class AddStatusToCompanyUserTable < ActiveRecord::Migration
  def change
    add_column :company_users, :active, :boolean, default: true
    User.where("aasm_state <> 'invited'").update_all(confirmed_at: DateTime.now)
    CompanyUser.joins(:user).where(users: {aasm_state: ['invited', 'inactive']}).update_all(active: false)
    remove_column :users, :aasm_state
  end
end
