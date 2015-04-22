class AddDobZipColumnsToInviteRsvps < ActiveRecord::Migration
  def change
    add_column :invite_rsvps, :date_of_birth, :string
    add_column :invite_rsvps, :zip_code, :string
  end
end
