class AddRsvpdToInviteIndividuals < ActiveRecord::Migration
  def change
    add_column :invite_individuals, :rsvpd, :boolean, default: false
    add_column :invite_individuals, :active, :boolean, default: true
  end
end
