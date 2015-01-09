class RemoveEventDateColumnInInvitesTable < ActiveRecord::Migration
  def change
    remove_column :invites, :event_date, :string
  end
end
