class DropEventResultsTable < ActiveRecord::Migration
  def change
    drop_table :event_results
  end
end
