class AddUserTrackingFieldsToInviteRsvps < ActiveRecord::Migration
  def change
    add_column :invite_rsvps, :created_by_id, :integer
    add_column :invite_rsvps, :updated_by_id, :integer
  end
end
