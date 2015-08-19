class CreateHoursFields < ActiveRecord::Migration
  def change
    create_table :hours_fields do |t|
      t.references :venue, index: true
      t.integer :day
      t.string :hour_open
      t.string :hour_close
      t.timestamps
    end
  end
end
