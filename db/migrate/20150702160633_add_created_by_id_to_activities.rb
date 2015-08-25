class AddCreatedByIdToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :created_by_id, :integer
  end
end
