class AddUserTrackingFieldsToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :created_by_id, :integer
    add_column :invites, :updated_by_id, :integer
  end
end
