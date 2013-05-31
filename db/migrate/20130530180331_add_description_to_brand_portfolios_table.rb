class AddDescriptionToBrandPortfoliosTable < ActiveRecord::Migration
  def change
    add_column :brand_portfolios, :description, :text
  end
end
