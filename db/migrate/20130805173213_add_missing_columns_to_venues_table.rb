class AddMissingColumnsToVenuesTable < ActiveRecord::Migration
  def change
    add_column :venues, :avg_impressions_hour, :decimal, :precision => 6, :scale => 2, :default => 0
    add_column :venues, :avg_impressions_cost, :decimal, :precision => 8, :scale => 2, :default => 0
  end
end
