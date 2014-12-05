class RemoveVistiIdColumnFromEventsTable < ActiveRecord::Migration
  def change
    remove_column :events, :visit_id
  end
end
