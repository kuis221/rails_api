class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer :company_id
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :email
      t.string :phone_number
      t.string :street1
      t.string :street2
      t.string :country
      t.string :state
      t.string :city
      t.string :zip_code

      t.timestamps
    end
  end
end
