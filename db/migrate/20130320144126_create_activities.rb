class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :name

      t.datetime :start_date
      t.datetime :end_date

      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
