class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :company_user
      t.string :message
      t.string :level
      t.text :path
      t.string :icon

      t.timestamps
    end
    add_index :notifications, :company_user_id
  end
end
