class RenameInviteRsvpTable < ActiveRecord::Migration
  def change
    rename_table :invite_rsvps, :invite_individuals
  end
end
