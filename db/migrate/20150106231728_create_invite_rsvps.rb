class CreateInviteRsvps < ActiveRecord::Migration
  def change
    create_table :invite_rsvps do |t|
      t.references :invite, index: true
      t.integer :registrant_id
      t.date :date_added
      t.string :email
      t.string :mobile_phone
      t.boolean :mobile_signup
      t.string :first_name
      t.string :last_name
      t.string :attended_previous_bartender_ball
      t.boolean :opt_in_to_future_communication
      t.integer :primary_registrant_id
      t.string :bartender_how_long
      t.string :bartender_role

      t.timestamps
    end
  end
end
