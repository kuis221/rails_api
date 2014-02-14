class AddStartEndDatesToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :start_date, :date
    add_column :campaigns, :end_date, :date
  end
end
