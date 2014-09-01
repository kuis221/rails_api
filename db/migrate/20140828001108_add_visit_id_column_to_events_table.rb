class AddVisitIdColumnToEventsTable < ActiveRecord::Migration
  def change
    add_column :events, :visit_id, :integer
    add_index :events, :visit_id
  end
end
