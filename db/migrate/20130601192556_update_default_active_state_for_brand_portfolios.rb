class UpdateDefaultActiveStateForBrandPortfolios < ActiveRecord::Migration
  def up
    change_column :brand_portfolios, :active, :boolean, default: true
  end
  def down
    change_column :brand_portfolios, :active, :boolean, default: false
  end
end
