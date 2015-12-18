class RemoveAreaIdFromInvites < ActiveRecord::Migration
  def change
    remove_column :invites, :area_id, :integer
  end
end
