class AddDescriptionColumnToVisitsTable < ActiveRecord::Migration
  def change
    add_column :brand_ambassadors_visits, :description, :text
  end
end
