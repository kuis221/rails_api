class AddPhoneNumberToVenues < ActiveRecord::Migration
  def up
    add_column :venues, :phone_number, :string
  end
  def down
    remove_column :venues, :phone_number
  end
end
