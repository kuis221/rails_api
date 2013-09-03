class AlterGoalsTableForGoalable < ActiveRecord::Migration
  def up
    add_column :goals, :goalable_id, :integer
    add_column :goals, :goalable_type, :string
    add_column :goals, :parent_id, :integer
    add_column :goals, :parent_type, :string
    add_index :goals, [:goalable_id, :goalable_type]
    execute "UPDATE goals set goalable_id=campaign_id, goalable_type='Campaign'"
    remove_column :goals, :campaign_id
  end

  def down
    add_column :goals, :campaign_id, :integer
    execute "UPDATE goals set campaign_id=goalable_id"
    remove_column :goals, :goalable_id
    remove_column :goals, :goalable_type
    remove_column :goals, :parent_id
    remove_column :goals, :parent_type
  end
end
