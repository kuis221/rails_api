class AddVerificationCodeToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :phone_number_verified, :boolean
    add_column :users, :phone_number_verification, :string
  end
end
