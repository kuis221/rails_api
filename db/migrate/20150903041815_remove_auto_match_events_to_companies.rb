class RemoveAutoMatchEventsToCompanies < ActiveRecord::Migration
  def up
    remove_column :companies, :auto_match_events
    Company.all.each do |c|
      c.auto_match_events = 1
      c.save
    end
  end

  def down
    add_column :companies, :auto_match_events, :boolean, default: true
  end
end
