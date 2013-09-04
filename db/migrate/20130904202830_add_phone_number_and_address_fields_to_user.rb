class AddPhoneNumberAndAddressFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :phone_number, :string
    add_column :users, :street_address, :string
    add_column :users, :unit_number, :string
    add_column :users, :zip_code, :string
  end
end
