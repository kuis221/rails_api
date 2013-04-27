class AddProfileFieldsToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :country, :string, limit: 4
    add_column :users, :state, :string
    add_column :users, :city, :string
  end
end
