class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.references :event, index: true
      t.references :venue, index: true
      t.string :market
      t.integer :invitees, default: 0
      t.integer :rsvps_count, default: 0
      t.integer :attendees, default: 0
      t.date :final_date

      t.timestamps
    end
  end
end
