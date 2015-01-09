class AddActiveColumnToInvitesTable < ActiveRecord::Migration
  def change
    add_column :invites, :active, :boolean, default: true
  end
end
