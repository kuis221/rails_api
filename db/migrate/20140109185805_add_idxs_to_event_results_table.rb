class AddIdxsToEventResultsTable < ActiveRecord::Migration
  def change
    add_index :event_results, :event_id
    add_index :event_results, :form_field_id
    add_index :event_results, [:event_id, :form_field_id]
  end
end
