class CreateAlertsUsers < ActiveRecord::Migration
  def change
    create_table :alerts_users do |t|
      t.references :company_user
      t.string :name
      t.integer :version

      t.timestamps
    end
    add_index :alerts_users, :company_user_id
  end
end
