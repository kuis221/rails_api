class AddStatusToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :aasm_state, :string
    User.all.each{|u| u.update_attribute(:aasm_state, 'inactive') }
  end
end
