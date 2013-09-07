class AddFirstAndLastEventsToCampaigns < ActiveRecord::Migration
  def up
    add_column :campaigns, :first_event_id, :integer
    add_column :campaigns, :last_event_id,  :integer
    add_column :campaigns, :first_event_at, :datetime
    add_column :campaigns, :last_event_at, :datetime

    Campaign.all.each do |c|
      c.first_event = c.events.order('start_at').first
      c.last_event = c.events.order('end_at').last
      c.save if c.changed?
    end
  end

  def down
    remove_column :campaigns, :first_event_id
    remove_column :campaigns, :last_event_id
    remove_column :campaigns, :first_event_at
    remove_column :campaigns, :last_event_at
  end
end
