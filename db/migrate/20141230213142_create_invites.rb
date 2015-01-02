class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.references :invitable, polymorphic: true, index: true
      t.references :venue, index: true
      t.integer :invitees
      t.integer :rsvps
      t.integer :attendees
      t.date :final_date
      t.date :event_date
      t.integer :registrant_id
      t.date :date_added
      t.string :email
      t.string :mobile_phone
      t.boolean :mobile_signup
      t.string :first_name
      t.string :last_name
      t.boolean :attended_previous_bartender_ball
      t.boolean :opt_in_to_future_communication
      t.integer :primary_registrant_id
      t.string :bartender_how_long
      t.string :bartender_role

      t.timestamps
    end
  end
end
