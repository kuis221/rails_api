class CreateCompanyUsers < ActiveRecord::Migration
  def change
    create_table :company_users do |t|
      t.references :company
      t.references :user
      t.references :role

      t.timestamps
    end
    User.all.each do |u|
      u.company_users << CompanyUser.new(company_id: u.attributes['company_id'], role_id: u.attributes['role_id'])
    end

    add_index :company_users, :company_id
    add_index :company_users, :user_id

    remove_column :users, :company_id
    remove_column :users, :role_id
  end
end
