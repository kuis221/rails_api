class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :event
      t.string :title
      t.datetime :due_at
      t.references :user
      t.boolean :completed

      t.timestamps
    end
    add_index :tasks, :event_id
    add_index :tasks, :user_id
  end
end
