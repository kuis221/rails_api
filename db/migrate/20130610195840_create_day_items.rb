class CreateDayItems < ActiveRecord::Migration
  def change
    create_table :day_items do |t|
      t.references :day_part
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end
