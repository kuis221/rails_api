class RenameEventsFieldOnVenuesTable < ActiveRecord::Migration
  def up
    rename_column :venues, :events, :events_count
  end

  def down
  end
end
