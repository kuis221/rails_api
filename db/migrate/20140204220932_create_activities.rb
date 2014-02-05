class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :activity_type
      t.references :activitable, polymorphic: true
      t.boolean :active, default: true
      t.references :company_user
      t.datetime :activity_date

      t.timestamps
    end
    add_index :activities, :activity_type_id
    add_index :activities, [:activitable_id, :activitable_type]
    add_index :activities, :company_user_id
  end
end
