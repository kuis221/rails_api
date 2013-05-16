class AddActiveColumnToTasksTable < ActiveRecord::Migration
  def change
    add_column :tasks, :active, :boolean, default: true
  end
end
