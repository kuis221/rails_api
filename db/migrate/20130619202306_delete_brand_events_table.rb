class DeleteBrandEventsTable < ActiveRecord::Migration
  def change
    drop_table :brands_events
  end
end
