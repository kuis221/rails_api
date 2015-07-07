class AddUpdatedByIdToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :updated_by_id, :integer
  end
end
