class CreateDateItems < ActiveRecord::Migration
  def change
    create_table :date_items do |t|
      t.references :date_range
      t.date :start_date
      t.date :end_date
      t.boolean :recurrence, default: false
      t.string :recurrence_type
      t.integer :recurrence_period
      t.string :recurrence_days

      t.timestamps
    end
  end
end
