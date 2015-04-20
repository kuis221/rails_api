class AddAttendedToInviteRsvps < ActiveRecord::Migration
  def change
    add_column :invite_rsvps, :attended, :boolean
  end
end
