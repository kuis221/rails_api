class AddScoringFieldsToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :score_impressions, :integer
    add_column :venues, :score_cost, :integer
  end
end
