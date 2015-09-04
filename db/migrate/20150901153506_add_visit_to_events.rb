class AddVisitToEvents < ActiveRecord::Migration
  def up
    add_column :events, :visit_id, :integer
    add_index :events, [:visit_id]
  end

  def down
    remove_index :events, [:visit_id]
    remove_column :events, :visit_id
  end
end
