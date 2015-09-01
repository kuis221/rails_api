class AddAutoMatchEventsToCompanies < ActiveRecord::Migration
  def up
    add_column :companies, :auto_match_events, :boolean, default: true
    Company.update_all(auto_match_events: true)
  end

  def down
    remove_column :companies, :auto_match_events
  end
end
