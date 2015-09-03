class UpdateAutoMatchEventsToCompanies < ActiveRecord::Migration
  def change
    Company.all.each do |c|
      c.auto_match_events = 1
      c.save
    end
  end
end
