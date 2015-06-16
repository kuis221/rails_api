class AddCompanyToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :company_name, :string
  end
end
