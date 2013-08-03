class AddPromoHoursColumnToEventsTable < ActiveRecord::Migration
  def up
    add_column :events, :promo_hours, :decimal, :precision => 6, :scale => 2, :default => 0
  end
  def down
    add_column :events, :promo_hours, :decimal, :precision => 6, :scale => 2, :default => 0
  end
end
