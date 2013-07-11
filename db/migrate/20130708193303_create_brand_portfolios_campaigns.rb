class CreateBrandPortfoliosCampaigns < ActiveRecord::Migration
  def change
    create_table :brand_portfolios_campaigns do |t|
      t.references :brand_portfolio
      t.references :campaign
    end
    add_index :brand_portfolios_campaigns, :brand_portfolio_id
    add_index :brand_portfolios_campaigns, :campaign_id
  end
end
