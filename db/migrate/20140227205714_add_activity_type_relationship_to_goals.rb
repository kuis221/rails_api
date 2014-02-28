class AddActivityTypeRelationshipToGoals < ActiveRecord::Migration
  def change
    add_column :goals, :activity_type_id, :integer
  end
end
