class AddCreatedByAndUpdatedByToActivities < ActiveRecord::Migration
  def change
    add_reference :activities, :created_by, index: true
    add_reference :activities, :updated_by, index: true
  end
end
