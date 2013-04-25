class CreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.string :name

      t.timestamps
    end

    add_column :users, :user_group_id, :integer
    add_index :users, :user_group_id
  end
end
