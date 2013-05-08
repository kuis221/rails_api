class AddCreatedAndUpdatedByFieldsToTasksTable < ActiveRecord::Migration
  def change
    add_column :tasks, :created_by_id, :integer
    add_column :tasks, :updated_by_id, :integer

    add_column :users, :created_by_id, :integer
    add_column :users, :updated_by_id, :integer
  end
end
